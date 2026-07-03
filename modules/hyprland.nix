{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  home.file.".config/hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/hyprland.conf";
  home.file.".config/hypr/view-logs.sh".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/scripts/view-logs.sh";
  home.file.".config/hypr/screenshot.sh".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/scripts/screenshot.sh";
  home.file.".config/hypr/kbd-backlight.sh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/scripts/kbd-backlight.sh";
  home.file.".config/hypr/brightness.sh".source   = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/scripts/brightness.sh";
  home.file.".config/hypr/space-action.sh".source  = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/scripts/space-action.sh";
}
