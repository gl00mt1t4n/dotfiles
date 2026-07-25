{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.hermes-agent;
  hermesHome = "${cfg.stateDir}/.hermes";
  desktopRemoteToken = "/home/gl00m/.config/Hermes/hermes-remote.token";
  desktopLauncher = pkgs.writeShellScriptBin "hermes-desktop" ''
    # Retained as the known-good shared-state launcher during the remote pilot.
    export HERMES_HOME=${lib.escapeShellArg hermesHome}
    exec ${pkgs.hermes-desktop}/bin/hermes-desktop "$@"
  '';
  remotePilotLauncher = pkgs.writeShellScriptBin "hermes-desktop-remote" ''
    # The pilot is explicitly opt-in; it proves the remote backend before the
    # shared-state launcher, symlink, timer, or permissions are retired.
    token_file=${lib.escapeShellArg desktopRemoteToken}
    if [ ! -r "$token_file" ]; then
      echo "Hermes remote token is missing: $token_file" >&2
      echo "Run nixos-rebuild switch to create it, then relaunch Hermes." >&2
      exit 1
    fi
    export HERMES_DESKTOP_REMOTE_URL="http://127.0.0.1:9119"
    export HERMES_DESKTOP_REMOTE_TOKEN="$(< "$token_file")"
    exec ${pkgs.hermes-desktop}/bin/hermes-desktop "$@"
  '';
  recoveryLauncher = pkgs.writeShellScriptBin "hermes-recovery" ''
    # Deliberately separate from /var/lib/hermes/.hermes.  This remains useful
    # when the production gateway or remote Desktop backend is unavailable.
    export HERMES_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes-recovery"
    mkdir -p "$HERMES_HOME"
    exec ${cfg.package}/bin/hermes --tui "$@"
  '';
  desktopEntry = pkgs.makeDesktopItem {
    name = "hermes";
    desktopName = "Hermes";
    genericName = "Hermes Agent desktop client";
    exec = "hermes-desktop";
    terminal = false;
    categories = [ "Development" "Utility" ];
  };
  remotePilotEntry = pkgs.makeDesktopItem {
    name = "hermes-remote-pilot";
    desktopName = "Hermes Remote Pilot";
    genericName = "Hermes Agent remote backend validation client";
    exec = "hermes-desktop-remote";
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

      # Kept during the pilot so the existing Desktop launcher remains a
      # rollback path. Stage 2 removes this after remote health is verified.
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

    # Kept during the pilot; stage 2 removes the shared host CLI wrapper.
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

      # Linear's hosted MCP endpoint uses OAuth. `mcp-remote` bridges its
      # authenticated StreamableHTTP connection to Hermes' stdio MCP client;
      # its token cache remains service-private under /data.
      mcp_servers.linear = {
        command = "/usr/bin/npx";
        args = [
          "-y"
          "mcp-remote"
          "https://mcp.linear.app/mcp"
        ];
        env = {
          MCP_REMOTE_CONFIG_DIR = "/data/.mcp-auth/linear";
        };
        connect_timeout = 60;
        timeout = 120;
        sampling.enabled = false;
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
      # Available to the backend terminal rail. These have no credentials
      # provisioned here; host-side Codex/Claude remain the primary break-glass
      # route and use the user's own auth stores.
      codex
      claude-code
      tmux
    ];
  };

  # Keep the known-good launcher and add an opt-in remote-pilot entry. The
  # independent host recovery TUI is available in both migration stages.
  environment.systemPackages = [
    desktopLauncher
    desktopEntry
    remotePilotLauncher
    remotePilotEntry
    recoveryLauncher
  ];

  # Run the upstream-supported Desktop backend in the existing service
  # container, as the same `hermes` identity that owns the gateway and state.
  # Docker uses host networking, but this bind is loopback-only.
  systemd.services.hermes-serve = {
    description = "Hermes Desktop remote backend";
    wantedBy = [ "multi-user.target" ];
    requires = [ "hermes-agent.service" ];
    after = [ "hermes-agent.service" ];
    bindsTo = [ "hermes-agent.service" ];
    partOf = [ "hermes-agent.service" ];
    path = [ pkgs.bash pkgs.coreutils pkgs.docker ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 30;
    };
    script = ''
      set -euo pipefail
      for _ in $(seq 1 30); do
        if docker exec --user ${cfg.user} hermes-agent /bin/true 2>/dev/null; then
          break
        fi
        sleep 1
      done
      docker exec --user ${cfg.user} hermes-agent /bin/true >/dev/null
      exec docker exec --user ${cfg.user} hermes-agent /bin/bash -lc '
        set -eu
        export HERMES_HOME=/data/.hermes
        export HERMES_DASHBOARD_SESSION_TOKEN="$(cat /data/.hermes/desktop-remote.token)"
        exec /data/current-package/bin/hermes serve --host 127.0.0.1 --port 9119
      '
    '';
  };

  # A configuration build is safe, but even the remote pilot must not run
  # against the WAL-reset-vulnerable embedded SQLite runtime.
  system.activationScripts.hermes-sqlite-release-gate = {
    deps = [ "users" ];
    text = ''
      set -eu
      tmp_home="$(${pkgs.coreutils}/bin/mktemp -d)"
      trap '${pkgs.coreutils}/bin/rm -rf "$tmp_home"' EXIT
      doctor_output="$(HOME="$tmp_home" HERMES_HOME="$tmp_home/.hermes" ${cfg.package}/bin/hermes doctor 2>&1)"
      if printf '%s\n' "$doctor_output" | ${pkgs.gnugrep}/bin/grep -q 'WAL-reset bug'; then
        printf '%s\n' "$doctor_output" >&2
        echo 'Refusing Hermes single-owner migration: the selected package has a vulnerable SQLite WAL runtime.' >&2
        echo 'Update services.hermes-agent.package/input until hermes doctor no longer reports the WAL-reset bug, then retry.' >&2
        exit 1
      fi
    '';
  };

  # Stable loopback session token: the backend receives the service-private
  # copy, while Desktop receives a user-private copy only through its launcher.
  # This avoids a brief local-server fallback during first Desktop startup.
  system.activationScripts.hermes-desktop-remote-token = {
    deps = [ "hermes-agent-setup" "hermes-sqlite-release-gate" ];
    text = ''
      set -eu
      token_file=${lib.escapeShellArg "${hermesHome}/desktop-remote.token"}
      desktop_token=${lib.escapeShellArg desktopRemoteToken}
      if [ ! -s "$token_file" ]; then
        umask 077
        ${pkgs.coreutils}/bin/install -d -o ${cfg.user} -g ${cfg.group} -m 0700 "$(dirname "$token_file")"
        token_tmp="$(${pkgs.coreutils}/bin/mktemp "$(dirname "$token_file")/.desktop-remote-token.XXXXXX")"
        trap '${pkgs.coreutils}/bin/rm -f "$token_tmp"' EXIT
        ${pkgs.openssl}/bin/openssl rand -base64 48 > "$token_tmp"
        ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} "$token_tmp"
        ${pkgs.coreutils}/bin/chmod 0600 "$token_tmp"
        ${pkgs.coreutils}/bin/mv "$token_tmp" "$token_file"
        trap - EXIT
      fi
      ${pkgs.coreutils}/bin/install -d -o gl00m -g users -m 0700 "$(dirname "$desktop_token")"
      ${pkgs.coreutils}/bin/install -o gl00m -g users -m 0600 "$token_file" "$desktop_token"
    '';
  };

  # Stage 1 deliberately retains the known-good shared-state reconciliation
  # loop. Stage 2 removes this only after the remote backend has passed its
  # health/soak checks and private tmpfiles rules are ready to replace it.
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
        [ -d "$state" ] || return 0
        ${pkgs.coreutils}/bin/chgrp --no-dereference ${lib.escapeShellArg cfg.group} "$state"
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
