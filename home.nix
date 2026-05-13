{ pkgs, ... }:
{
  imports = [
    ./modules/shell.nix
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
    ];
  };
}
