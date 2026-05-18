{ pkgs, caelestiaSpotify, ... }:
{
  home.packages = [
    caelestiaSpotify
    pkgs.spicetify-cli
  ];

  xdg.configFile."spicetify/Themes/caelestia".source = ../config/spicetify/Themes/caelestia;
}
