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
    grim
    slurp
    brightnessctl
    playerctl
    cliphist   # clipboard history daemon + query tool
    wofi       # dmenu-style picker used by clipboard history
    blueman    # bluetooth device manager GUI
    mpv        # video/audio player (caelestia uses it for media playback)
    imv        # lightweight Wayland image viewer
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
    # Home Manager places bashrcExtra before its interactive-shell guard, so keep
    # it limited to cheap, side-effect-free definitions. Prompt/hooks belong in
    # initExtra below; otherwise non-interactive shells that source ~/.bashrc can
    # inherit readline/prompt setup and break automation/session startup.
    bashrcExtra = ''
      nixrebuild() {
        local dotfiles="''${DOTFILES_DIR:-$HOME/dotfiles}"
        local dry_cmd build_cmd

        case "$1" in
          -system)
            dry_cmd="sudo nixos-rebuild dry-activate --flake $dotfiles#nixos"
            build_cmd="make -C $dotfiles system" ;;
          -user)
            dry_cmd="home-manager build --flake $dotfiles#gl00m"
            build_cmd="make -C $dotfiles user" ;;
          *)
            dry_cmd="sudo nixos-rebuild dry-activate --flake $dotfiles#gl00m-full"
            build_cmd="make -C $dotfiles full" ;;
        esac

        git -C "$dotfiles" add .
        read -r -p "Commit message (blank to skip): " msg
        [ -n "$msg" ] && git -C "$dotfiles" commit -m "$msg"

        if eval "$dry_cmd"; then
          [ -n "$msg" ] && git -C "$dotfiles" push
          eval "$build_cmd"
        else
          [ -n "$msg" ] && git -C "$dotfiles" reset --soft HEAD~1
          return 1
        fi
      }
    '';
    initExtra = ''
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
      eval "$(${pkgs.fzf}/bin/fzf --bash)"
    '';
    shellAliases = {
      dotfiles = "cd \${DOTFILES_DIR:-$HOME/dotfiles}";
      nixconf  = "sudo nvim \${DOTFILES_DIR:-$HOME/dotfiles}/configuration.nix";
      hyprconf = "nvim \${DOTFILES_DIR:-$HOME/dotfiles}/config/hypr/hyprland.conf";
      start-hyprland = "AQ_NO_ATOMIC=1 /run/current-system/sw/bin/start-hyprland";
      ls       = "eza --icons";
      ll       = "eza -la --icons";
      cat      = "bat";
    };
  };
}
