{ ... }:
{
  home.file.".config/hypr/hyprland.conf".source = ../config/hypr/hyprland.conf;
  home.file.".config/hypridle/hypridle.conf".source = ../config/hypr/hypridle.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../config/hypr/hyprlock.conf;
  home.file.".config/hyprpaper/hyprpaper.conf".source = ../config/hypr/hyprpaper.conf;
  home.file.".config/mako/config".source = ../config/mako/config;

  home.file.".config/hypr/view-logs.sh" = {
    source = ../config/hypr/view-logs.sh;
    executable = true;
  };

  home.file.".config/hypr/screenshot.sh" = {
    source = ../config/hypr/screenshot.sh;
    executable = true;
  };
}
