{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  home.file.".config/kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/kitty/kitty.conf";
}
