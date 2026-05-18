{ ... }:
{
  home.file.".config/hypr/hyprland.conf".source = ../config/hypr/hyprland.conf;
  home.file.".config/hypridle/hypridle.conf".source = ../config/hypr/hypridle.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../config/hypr/hyprlock.conf;
  home.file.".config/hyprpaper/hyprpaper.conf".source = ../config/hypr/hyprpaper.conf;

  home.file.".config/hypr/view-logs.sh" = {
    source = ../config/hypr/scripts/view-logs.sh;
    executable = true;
  };

  home.file.".config/hypr/screenshot.sh" = {
    source = ../config/hypr/scripts/screenshot.sh;
    executable = true;
  };

  home.file.".config/hypr/kbd-backlight.sh" = {
    source = ../config/hypr/scripts/kbd-backlight.sh;
    executable = true;
  };

  home.file.".config/hypr/brightness.sh" = {
    source = ../config/hypr/scripts/brightness.sh;
    executable = true;
  };
}
