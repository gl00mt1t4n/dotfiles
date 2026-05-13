{ lib, pkgs, ... }:
{
  home = {
    username = "gl00m";
    homeDirectory = "/home/gl00m";
    stateVersion = "25.11";

    packages = with pkgs; [
      kitty
      firefox
      vim
      neovim
      git
    ];
  };

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      nixrebuild() {
        case "$1" in
          -system) cd /home/gl00m/dotfiles && make system ;;
          -user)   cd /home/gl00m/dotfiles && make user ;;
          *)       cd /home/gl00m/dotfiles && make full ;;
        esac
      }
    '';
    shellAliases = {
      dotfiles  = "cd /home/gl00m/dotfiles";
      nixconf   = "sudo vim /home/gl00m/dotfiles/configuration.nix";
      hyprconf  = "vim $HOME/.config/hypr/hyprland.conf";
    };
  };
}
