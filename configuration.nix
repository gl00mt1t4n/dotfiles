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
  users.users.gl00m = {
    isNormalUser = true;
    description = "gl00m";
    extraGroups = [ "networkmanager" "wheel" ];
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

  # System state version
  system.stateVersion = "25.11";

  # Bluetooth enabling
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Waybar enabling
  programs.waybar.enable = true;

}
