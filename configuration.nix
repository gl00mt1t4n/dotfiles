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
    environmentFiles = [ config.age.secrets.hermes-env.path ];
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

  # Hermes .env readable by hermes group
  systemd.tmpfiles.rules = [
    "f /var/lib/hermes/.hermes/.env 640 hermes hermes -"
     "f /var/lib/hermes/.hermes/.hermes_history 660 hermes hermes -"
  ];

  # Agenix secrets
  age.secrets.hermes-env.file = ./secrets/hermes-env.age;
  age.identityPaths = [ "/home/gl00m/.config/sops/age/keys.txt" ];

  # Audio
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
};
security.rtkit.enable = true;

# Font discovery

fonts.fontconfig.enable = true;
}
