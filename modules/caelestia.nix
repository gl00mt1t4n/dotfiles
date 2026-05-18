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
    default_wallpaper="$HOME/.config/caelestia/wallpapers/default.png"

    if [ ! -s "$wallpaper_state" ] || [ ! -e "$(cat "$wallpaper_state" 2>/dev/null)" ]; then
      mkdir -p "$(dirname "$wallpaper_state")"
      printf '%s\n' "$default_wallpaper" > "$wallpaper_state"
    fi
  '';
}
