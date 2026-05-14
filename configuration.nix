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

  # Hermes Agent config
  services.hermes-agent = {
  	enable = true;
	container = {
		enable = true;
		hostUsers = [ "gl00m" ];
	};
	settings = {
		model = {
			base_url = "https://api.groq.com/openai/v1";
      			default = "llama-3.3-70b-versatile";	};
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
	environmentFiles = [ "config.age.secrets.hermes-env.path" ];
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
  #Hermes no password permission
  security.sudo.extraRules = [{
  users = [ "gl00m" ];
  commands = [{
    command = "/run/current-system/sw/bin/docker";
    options = [ "NOPASSWD" ];
  }];
}];
  # Agenix should know secret
  age.secrets.hermes-env.file = ./secrets/hermes-env.age;
  age.identityPaths = [ "/home/gl00m/.config/sops/age/keys.txt" ];
}
