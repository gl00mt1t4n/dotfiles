{ caelestiaShell, lib, ... }:
let
  caelestiaConfig = ../config/caelestia;
in
{
  home.packages = [ caelestiaShell ];

  # Caelestia writes monitor overlays under ~/.config/caelestia/monitors/<screen>.
  # Keep repo config authoritative, but install it into a writable directory.
  home.activation.installCaelestiaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="$HOME/.config/caelestia"

    if [ -L "$config_dir" ]; then
      rm "$config_dir"
    fi

    mkdir -p "$config_dir"
    cp -RL ${caelestiaConfig}/. "$config_dir/"
    mkdir -p "$config_dir/monitors"
    chmod -R u+w "$config_dir"
  '';

  home.activation.seedCaelestiaWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    wallpaper_state="$HOME/.local/state/caelestia/wallpaper/path.txt"
    wallpaper_dir="$HOME/Pictures/Wallpapers"

    mkdir -p "$wallpaper_dir"

    if [ ! -s "$wallpaper_state" ] || [ ! -e "$(cat "$wallpaper_state" 2>/dev/null)" ]; then
      first_wallpaper="$(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort | head -n1)"
      if [ -n "$first_wallpaper" ]; then
        mkdir -p "$(dirname "$wallpaper_state")"
        printf '%s\n' "$first_wallpaper" > "$wallpaper_state"
      fi
    fi
  '';
}
