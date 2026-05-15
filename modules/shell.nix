{ pkgs, ... }:
{
  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    fzf
    zoxide
    wl-clipboard 
    grim #screenshot
    slurp #screenshot editor
    brightnessctl
    playerctl

  ];

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
    };
  };

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
      nixconf  = "sudo nvim /home/gl00m/dotfiles/configuration.nix";
      hyprconf = "nvim /home/gl00m/dotfiles/config/hypr/hyprland.conf";
      ls       = "eza --icons";
      ll       = "eza -la --icons";
      cat      = "bat";
    };
  };
}
