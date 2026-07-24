{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/hermes.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    # VPN plugins for Private Internet Access OpenVPN profiles.
    plugins = with pkgs; [ networkmanager-openvpn ];
  };

  # Locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.users.gl00m = {
    isNormalUser = true;
    description = "gl00m";
    extraGroups = [ "networkmanager" "wheel" "video" "i2c" ];
  };

  nixpkgs.config.allowUnfree = true;

  # System-level packages and services.
  # Put hardware/boot/driver/service tools here. Put normal GUI/user apps in
  # modules/apps.nix so day-to-day installs have one obvious home.
  environment.systemPackages = with pkgs; [
    vim
    home-manager
    gnumake
    asusctl
    supergfxctl
    power-profiles-daemon
    libva-utils
    mesa-demos
    vulkan-tools
    wayland-utils
    codex
    claude-desktop
  ];

  # Steam itself is managed by NixOS. Steam games are normal Steam-managed user
  # data, not Nix packages; install/uninstall them inside Steam as usual.
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # Shell
  programs.bash.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # hyprland portal handles screencopy (screen sharing); gtk portal handles file pickers etc.
  # config.hyprland.default tells the portal dispatcher which backend to use per interface.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.hyprland.default = [ "hyprland" "gtk" ];
  };

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Intel video acceleration. Without the iHD VA-API driver, Zen/Firefox can
  # fall back to CPU video decode, causing high browser CPU and visible stutter.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API iHD driver for modern Intel/Arc GPUs
      vpl-gpu-rt         # oneVPL runtime used by newer Intel media stacks
      intel-compute-runtime
      libva-utils        # vainfo for diagnostics
    ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables.FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
  environment.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Allow running dynamically-linked ELF binaries downloaded outside Nix
  programs.nix-ld.enable = true;

  # AppImage support: binfmt lets the kernel run AppImages directly (double-click in Thunar works)
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Keep only the last 10 boot generations and garbage collect weekly
  boot.loader.systemd-boot.configurationLimit = 10;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Compressed RAM-backed swap. Ceiling is 50% of RAM (~15 GiB); actual use
  # is on-demand. Prevents OOM under load without touching the NVMe.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # System state version
  system.stateVersion = "25.11";

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      FastConnectable = true;
      Experimental = true;    # unlocks newer BT features (LE Audio, codec improvements)
    };
    Policy = {
      AutoEnable = true;
      ReconnectAttempts = 7;
      ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
    };
  };

  # i2c access for ddcutil (caelestia uses this for external monitor brightness)
  hardware.i2c.enable = true;

  # Thunar file manager with plugins (system-level so D-Bus and MIME are registered properly)
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin  # right-click to extract/create archives
      thunar-volman          # auto-mount USB drives and removable media
    ];
  };

  # Thumbnail generation for Thunar (images, video frames, PDFs)
  services.tumbler.enable = true;

  # Virtual filesystem — makes USB drives, MTP (Android), SMB shares mount in Thunar
  services.gvfs.enable = true;

  # UPower — required for caelestia battery status and power profile switching
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Keep the laptop out of power-saver by default. Power-saver was causing
  # visible video microstutter and occasional audio crackle on the 120 Hz panel.
  systemd.services.power-profile-balanced = {
    description = "Set balanced power profile";
    after = [ "dbus.service" "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    wantedBy = [ "graphical.target" ];
    path = [ pkgs.power-profiles-daemon pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "set-balanced-power-profile" ''
        for _ in $(seq 1 20); do
          if powerprofilesctl list >/dev/null 2>&1; then
            exec powerprofilesctl set balanced
          fi
          sleep 0.5
        done
        exec powerprofilesctl set balanced
      '';
    };
  };
  powerManagement.resumeCommands = ''
    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced || true
  '';

  # Closing the lid should suspend instead of fully terminating the graphical
  # session. This gives Zen a chance to keep its live session instead of relying
  # on crash/shutdown recovery.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Fonts
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Inter" "Noto Sans" "DejaVu Sans" ];
    serif = [ "Noto Serif" "DejaVu Serif" ];
    monospace = [ "MesloLGS Nerd Font Mono" "JetBrainsMono Nerd Font Mono" "DejaVu Sans Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };
  fonts.packages = with pkgs; [
    inter
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
    nerd-fonts.symbols-only
    nerd-fonts.caskaydia-cove  # caelestia monospace
    material-symbols            # caelestia icon font
    rubik                       # caelestia sans
  ];

  # Kernel (6.10+ required for full ASUS support)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Let brightness keys reach Hyprland instead of being consumed by the kernel
  boot.kernelParams = [ "video.brightness_switch_enabled=0" ];

  # ASUS hardware support
  services.asusd = {
    enable = true;
  };
  services.supergfxd.enable = true;
  systemd.services.supergfxd.path = [ pkgs.pciutils ];

  # asusd needs /etc/asusd to exist or it crashes on mount namespacing setup
  systemd.tmpfiles.rules = [ "d /etc/asusd 0755 root root -" ];

  # Give the video group write access to backlight and keyboard LED sysfs files
  # GROUP/MODE only apply to /dev nodes; sysfs files need explicit RUN+= chmod
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys%p/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys%p/brightness"
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys%p/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys%p/brightness"
  '';

}
