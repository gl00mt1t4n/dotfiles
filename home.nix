{ pkgs, config, ... }:
{
  imports = [
    ./modules/apps.nix
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

  # Softer, mac-like font rendering: light hinting + subpixel AA.
  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    hinting = "slight";
    subpixelRendering = "rgb";
    configFile.lcdfilter = {
      enable = true;
      priority = 10;
      label = "lcdfilter-default";
      text = ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
        <fontconfig>
          <match target="font">
            <edit mode="assign" name="lcdfilter">
              <const>lcddefault</const>
            </edit>
          </match>
        </fontconfig>
      '';
    };
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
    sessionPath = [ "$HOME/.local/bin" ];
  };

  home.file.".local/bin/appimage-install" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -e
      if [ -z "$1" ]; then
        echo "Usage: appimage-install <path-to.AppImage>"
        exit 1
      fi

      APPIMAGE=$(realpath "$1")
      WORKDIR=$(mktemp -d)
      trap 'rm -rf "$WORKDIR"' EXIT

      cd "$WORKDIR"
      "$APPIMAGE" --appimage-extract > /dev/null 2>&1

      DESKTOP=$(find squashfs-root -maxdepth 1 -name "*.desktop" | head -1)
      if [ -z "$DESKTOP" ]; then
        echo "No .desktop file found in AppImage"
        exit 1
      fi

      NAME=$(basename "$APPIMAGE")
      APPDIR="$HOME/Applications"
      mkdir -p "$APPDIR"
      DEST="$APPDIR/$NAME"

      if [ "$APPIMAGE" != "$DEST" ]; then
        cp "$APPIMAGE" "$DEST"
        chmod +x "$DEST"
      fi

      # Copy icons
      ICON_DIR="$HOME/.local/share/icons"
      mkdir -p "$ICON_DIR"
      find squashfs-root -maxdepth 2 \( -name "*.png" -o -name "*.svg" \) | head -1 | xargs -I{} cp {} "$ICON_DIR/"

      ICON_FILE=$(find squashfs-root -maxdepth 2 \( -name "*.png" -o -name "*.svg" \) | head -1)
      ICON_NAME=$(basename "''${ICON_FILE%.*}")

      # Write desktop entry pointing to the installed AppImage
      DESKTOP_OUT="$HOME/.local/share/applications/$(basename "$DESKTOP")"
      sed "s|Exec=.*|Exec=$DEST|; s|Icon=.*|Icon=$ICON_NAME|" "$DESKTOP" > "$DESKTOP_OUT"

      echo "Installed: $DEST"
      echo "Launcher entry: $DESKTOP_OUT"
    '';
  };

  home.file.".local/bin/zen-new-window" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      if [ "$#" -gt 0 ]; then
        exec zen --new-window "$@"
      fi

      # Start Zen normally when launched from the app menu/dock.  Using
      # --blank-window bypasses Zen/Firefox session restore, which made it look
      # like tabs were lost after reboot/shutdown.
      exec zen
    '';
  };

  # Zen is Firefox-based and stores profiles under ~/.config/zen in this package.
  # Keep session restore and hardware video decode preferences enabled for every
  # profile that exists. user.js survives rebuilds and applies on browser restart.
  home.activation.zenSessionRestore = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    for zen_dir in "$HOME/.config/zen" "$HOME/.zen"; do
      if [ -d "$zen_dir" ]; then
        while IFS= read -r -d ''' profile_dir; do
          user_js="$profile_dir/user.js"
          mkdir -p "$profile_dir"
          touch "$user_js"

          for pref in \
            'user_pref("browser.startup.page", 3);' \
            'user_pref("browser.sessionstore.resume_from_crash", true);' \
            'user_pref("browser.sessionstore.restore_on_demand", true);' \
            'user_pref("media.ffmpeg.vaapi.enabled", true);' \
            'user_pref("media.hardware-video-decoding.force-enabled", true);' \
            'user_pref("gfx.webrender.all", true);' \
            'user_pref("widget.dmabuf.force-enabled", true);' \
            'user_pref("media.av1.enabled", false);'
          do
            pref_name=$(printf '%s\n' "$pref" | ${pkgs.coreutils}/bin/cut -d'"' -f2)
            ${pkgs.gnused}/bin/sed -i "/user_pref(\"$pref_name\"/d" "$user_js"
            printf '%s\n' "$pref" >> "$user_js"
          done
        done < <(${pkgs.findutils}/bin/find "$zen_dir" -maxdepth 1 -type d \( -name "*.default*" -o -name "*.zen*" -o -name "*.release*" -o -name "*.Default Profile" \) -print0)
      fi
    done
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                          = [ "zen.desktop" ];
      "x-scheme-handler/http"              = [ "zen.desktop" ];
      "x-scheme-handler/https"             = [ "zen.desktop" ];
      "x-scheme-handler/about"             = [ "zen.desktop" ];
      "x-scheme-handler/unknown"           = [ "zen.desktop" ];
      "x-scheme-handler/chrome"            = [ "zen.desktop" ];
      "application/x-extension-htm"        = [ "zen.desktop" ];
      "application/x-extension-html"       = [ "zen.desktop" ];
      "application/xhtml+xml"              = [ "zen.desktop" ];
      "x-scheme-handler/claude-cli"        = [ "claude-code-url-handler.desktop" ];
      "x-scheme-handler/discord"           = [ "vesktop.desktop" ];
      "inode/directory"                    = [ "thunar.desktop" ];
      "video/mp4"                          = [ "mpv.desktop" ];
      "video/x-matroska"                   = [ "mpv.desktop" ];
      "video/webm"                         = [ "mpv.desktop" ];
      "audio/mpeg"                         = [ "mpv.desktop" ];
      "audio/ogg"                          = [ "mpv.desktop" ];
      "audio/flac"                         = [ "mpv.desktop" ];
      "image/png"                          = [ "imv.desktop" ];
      "image/jpeg"                         = [ "imv.desktop" ];
      "image/gif"                          = [ "imv.desktop" ];
      "image/webp"                         = [ "imv.desktop" ];
    };
  };

  # Allow home-manager to own mimeapps.list (overwrites any manually created copy)
  xdg.configFile."mimeapps.list".force = true;

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
