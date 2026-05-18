{ pkgs, ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/hyprland.nix
    ./modules/caelestia.nix
    ./modules/kitty.nix
    ./modules/neovim.nix
  ];

  home = {
    username = "gl00m";
    homeDirectory = "/home/gl00m";
    stateVersion = "25.11";
    packages = with pkgs; [
      kitty
      firefox
      git
      thunar
      pavucontrol
      claude-code
      zenity        # screenshot rename dialog
      brightnessctl # direct backlight control
      libnotify     # notify-send for kbd-backlight script
      playerctl
      zen-browser
    ];
  };
}
