{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.hermes-agent;
  hermesHome = "${cfg.stateDir}/.hermes";
  desktopLauncher = pkgs.writeShellScriptBin "hermes-desktop" ''
    export HERMES_HOME=${lib.escapeShellArg hermesHome}
    exec ${pkgs.hermes-desktop}/bin/hermes-desktop "$@"
  '';
  desktopEntry = pkgs.makeDesktopItem {
    name = "hermes";
    desktopName = "Hermes";
    genericName = "Hermes Agent desktop client";
    exec = "hermes-desktop";
    terminal = false;
    categories = [ "Development" "Utility" ];
  };
in
{
  services.hermes-agent = {
    enable = true;

    # Run Hermes inside the persistent Ubuntu container.
    container = {
      enable = true;
      backend = "docker";

      # Makes your normal CLI share the service's Hermes state.
      hostUsers = [ "gl00m" ];

      extraVolumes = [
        # Entire host filesystem, writable, visible inside Hermes as /host.
        "/:/host:rw"

        # The host CLI/Desktop may create absolute links below the managed
        # Hermes state directory. Mirror that path inside the container so
        # those links resolve for the gateway as well as on the host.
        "/var/lib/hermes:/var/lib/hermes:rw"
      ];

      extraOptions = [
        # Access host devices and substantially remove container restrictions.
        "--privileged"

        # Share host networking.

        # Allow visibility into host processes.
        "--pid=host"

        # Share host IPC namespace.
        "--ipc=host"
      ];
    };

    # Adds the Hermes CLI to your NixOS PATH and points it at the
    # same state used by the background agent.
    addToSystemPackages = true;

    settings = {
      model = {
        provider = "openai-codex";
        default = "gpt-5.6-terra";
      };

      terminal = {
        backend = "local";
        timeout = 300;
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };

    # Useful host/Nix tools available in the agent environment.
    extraPackages = with pkgs; [
      git
      curl
      wget
      jq
      ripgrep
      fd
      findutils
      coreutils
      util-linux
      procps
      pciutils
      usbutils
      ffmpeg
      imagemagick
    ];
  };

  # Launch the packaged Electron app independently of a terminal.
  environment.systemPackages = [ desktopLauncher desktopEntry ];

  # Hermes may create private files/directories after NixOS activation (for
  # example, auth.json at 0600 and cron at 0700). The gateway runs as hermes
  # while the desktop app and host CLI run as gl00m, a hermes-group member.
  # Repair both Hermes' state and its managed workspace; file owners remain
  # unchanged and .env files stay read-only to the shared group.
  systemd.services.hermes-state-permissions = {
    description = "Repair shared Hermes runtime-state permissions";

    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ cfg.stateDir ];
    };

    script = ''
      set -eu

      repair_shared_tree() {
        state="$1"
        if [ ! -d "$state" ]; then
          return 0
        fi

        ${pkgs.coreutils}/bin/chgrp --no-dereference ${lib.escapeShellArg cfg.group} "$state"

        # Hermes can atomically replace or remove state while this timer is
        # traversing it. Treat a vanished entry as already repaired, so one
        # transient race cannot abort the entire reconciliation pass.
        ${pkgs.findutils}/bin/find -P "$state" -xdev -type d \
          -exec ${pkgs.bash}/bin/bash -c '
            for path; do
              [ -d "$path" ] || continue
              ${pkgs.coreutils}/bin/chgrp --no-dereference ${lib.escapeShellArg cfg.group} "$path" 2>/dev/null || true
              ${pkgs.coreutils}/bin/chmod g+rwx,g+s "$path" 2>/dev/null || true
            done
          ' bash {} + 2>/dev/null || true

        ${pkgs.findutils}/bin/find -P "$state" -xdev -type f ! -name .env \
          -exec ${pkgs.bash}/bin/bash -c '
            for path; do
              [ -f "$path" ] || continue
              ${pkgs.coreutils}/bin/chgrp --no-dereference ${lib.escapeShellArg cfg.group} "$path" 2>/dev/null || true
              ${pkgs.coreutils}/bin/chmod g+rw "$path" 2>/dev/null || true
            done
          ' bash {} + 2>/dev/null || true
      }

      # Cron is written by the gateway with owner-private modes. Repair it
      # first so host CLI cron commands do not wait for the full state scan.
      repair_shared_tree ${lib.escapeShellArg "${hermesHome}/cron"}
      repair_shared_tree ${lib.escapeShellArg hermesHome}
      repair_shared_tree ${lib.escapeShellArg cfg.workingDirectory}
    '';
  };

  systemd.timers.hermes-state-permissions = {
    description = "Periodically repair shared Hermes runtime-state permissions";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      Persistent = true;
      Unit = "hermes-state-permissions.service";
    };
  };
}
