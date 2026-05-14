{ pkgs, ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/hyprland.nix
    ./modules/waybar.nix
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
    ];
  };
}
