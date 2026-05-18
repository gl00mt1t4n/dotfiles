{ caelestiaShell, lib, ... }:
{
  home.packages = [ caelestiaShell ];

  # Rebuilds copy repo config into the Nix store, keeping runtime state reproducible.
  xdg.configFile."caelestia" = {
    source = ../config/caelestia;
  };

  home.activation.seedCaelestiaWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    wallpaper_state="$HOME/.local/state/caelestia/wallpaper/path.txt"
    default_wallpaper="$HOME/.config/caelestia/wallpapers/default.png"

    if [ ! -s "$wallpaper_state" ] || [ ! -e "$(cat "$wallpaper_state" 2>/dev/null)" ]; then
      mkdir -p "$(dirname "$wallpaper_state")"
      printf '%s\n' "$default_wallpaper" > "$wallpaper_state"
    fi
  '';
}
