{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  # Add gloom to hermes for access
  users.users.gl00m = {
    isNormalUser = true;
    description = "gl00m";
    extraGroups = [ "networkmanager" "wheel" "video" "i2c" ];
  };

  # Packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    home-manager
    gnumake
    asusctl
    supergfxctl
    power-profiles-daemon
  ];

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
  fonts.packages = with pkgs; [
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
