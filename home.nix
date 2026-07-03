{ pkgs, config, ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/agents.nix
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

  # Softer, mac-like font rendering: light hinting + subpixel AA.
  fonts.fontconfig = {
    enable = true;
    hinting = "slight";
    subpixelRendering = "rgb";
    antialiasing = true;
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
      jq
      thunar
      pavucontrol
      claude-code
      zenity        # screenshot rename dialog
      brightnessctl # direct backlight control
      libnotify     # notify-send for kbd-backlight script
      playerctl
      nerd-fonts.meslo-lg          # Menlo-like terminal font
      zen-browser
      vesktop                      # Discord client with better Wayland behavior
      lxqt.lxqt-policykit         # polkit agent — auth dialogs for Thunar, BT, NM
      catppuccin-gtk               # GTK theme
      papirus-icon-theme           # icon set
      catppuccin-cursors.mochaDark # cursor theme
    ];
  };

  home.file.".local/bin/zen-new-window" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      if [ "$#" -gt 0 ]; then
        exec zen --new-window "$@"
      fi

      exec zen --blank-window
    '';
  };

  xdg.desktopEntries.zen = {
    name = "Zen Browser";
    genericName = "Web Browser";
    exec = "${config.home.homeDirectory}/.local/bin/zen-new-window %U";
    icon = "zen";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
    settings = {
      StartupWMClass = "zen";
    };
    actions = {
      new-window = {
        name = "New Window";
        exec = "${config.home.homeDirectory}/.local/bin/zen-new-window";
      };
      new-private-window = {
        name = "New Private Window";
        exec = "zen --private-window %U";
      };
      profile-manager-window = {
        name = "Profile Manager";
        exec = "zen --ProfileManager";
      };
    };
  };
}
