{ ... }:
{
  home.file.".config/hypr/hyprland.conf".source = ../config/hypr/hyprland.conf;

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
