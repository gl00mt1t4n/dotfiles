{ pkgs, ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/kitty.nix
  ];

  home = {
    username = "gl00m";
    homeDirectory = "/home/gl00m";
    stateVersion = "25.11";
    packages = with pkgs; [
      kitty
      firefox
      neovim
      vim
      git
      pavucontrol
      claude-code
      zenity      # screenshot rename dialog
      swayosd     # OSD overlay for volume and brightness keys
      zen-browser
    ];
  };
}
