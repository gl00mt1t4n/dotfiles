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
    #screenshots
    grim
    slurp #region selection

    # fonts
    noto-fonts
    noto-fonts-cjk-sans
    font-awesome
    (nerdfonts.override { fonts = [ "JetBrainsMono" "Firacode" ]; })

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
      nixconf  = "sudo nvim /home/gl00m/dotfiles/configuration.nix";
      hyprconf = "nvim /home/gl00m/dotfiles/config/hypr/hyprland.conf";
      ls       = "eza --icons";
      ll       = "eza -la --icons";
      cat      = "bat";
    };
  };
}
