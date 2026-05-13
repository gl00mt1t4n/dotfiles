{ pkgs, ... }:
{
  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    fzf
    zoxide
  ];

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      eval "$(zoxide init bash)"
      eval "$(fzf --bash)"
      nixrebuild() {
        case "$1" in
          -system) cd /home/gl00m/dotfiles && make system ;;
          -user)   cd /home/gl00m/dotfiles && make user ;;
          *)       cd /home/gl00m/dotfiles && make full ;;
        esac
      }
    '';
    shellAliases = {
      dotfiles = "cd /home/gl00m/dotfiles";
      nixconf  = "sudo vim /home/gl00m/dotfiles/configuration.nix";
      hyprconf = "vim $HOME/.config/hypr/hyprland.conf";
      ls       = "eza --icons";
      ll       = "eza -la --icons";
      cat      = "bat";
    };
  };
}
