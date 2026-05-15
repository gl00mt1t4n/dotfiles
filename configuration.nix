{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

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
    extraGroups = [ "networkmanager" "wheel" "hermes" ];
  };

  # Packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    home-manager
    gnumake
    hyprlauncher
    blueman
    hyprlock
    hypridle
    hyprpaper
    mako
    asusctl
    supergfxctl
  ];

  # Shell
  programs.bash.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keep only the last 10 boot generations and garbage collect weekly
  boot.loader.systemd-boot.configurationLimit = 10;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # System state version
  system.stateVersion = "25.11";

  # Bluetooth enabling
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Waybar enabling
  programs.waybar.enable = true;

  # Hermes Agent config
  # Hermes Agent
  services.hermes-agent = {
    enable = true;
    settings = {
      model = {
        base_url = "https://openrouter.ai/api/v1";
        default = "nvidia/nemotron-3-super-120b-a12b:free";
      };
      toolsets = [ "all" ];
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      terminal = {
        backend = "local";
        timeout = 180;
      };
    };
    environmentFiles = [ "/var/lib/hermes/env" ];
    documents = {
      "USER.md" = ./hermes/USER.md;
    };
    extraPackages = with pkgs; [
      ripgrep
      fd
      git
    ];
    addToSystemPackages = true;
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
    nerd-fonts.symbols-only
  ];

  # Kernel (6.10+ required for full ASUS support)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ASUS hardware support
  services.asusd = {
    enable = true;
  };
  services.supergfxd.enable = true;
  systemd.services.supergfxd.path = [ pkgs.pciutils ];
}
