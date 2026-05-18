{ caelestiaShell, ... }:
{
  home.packages = [ caelestiaShell ];

  # Rebuilds copy repo config into the Nix store, keeping runtime state reproducible.
  xdg.configFile."caelestia" = {
    source = ../config/caelestia;
  };
}
