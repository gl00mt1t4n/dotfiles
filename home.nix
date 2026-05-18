{ pkgs, config, ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/hyprland.nix
    ./modules/caelestia.nix
    ./modules/spicetify.nix
    ./modules/kitty.nix
    ./modules/neovim.nix
  ];

  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard+rimless";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        tweaks = [ "rimless" ];
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 24;
    };
    gtk4.theme = config.gtk.theme;
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
  };

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
      lxqt.lxqt-policykit         # polkit agent — auth dialogs for Thunar, BT, NM
      catppuccin-gtk               # GTK theme
      papirus-icon-theme           # icon set
      catppuccin-cursors.mochaDark # cursor theme
    ];
  };
}
