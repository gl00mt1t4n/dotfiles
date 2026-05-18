{ config, ... }:
{
  programs.caelestia = {
    enable = true;
    systemd.enable = false;  # autostarted via exec-once in hyprland.conf instead
    settings = {};            # empty → module generates no xdg.configFile entries
  };

  # Mirror the rest of dotfiles: dotfiles/config/caelestia → ~/.config/caelestia
  # Live symlink so editing shell.json or tokens takes effect without make user.
  xdg.configFile."caelestia" = {
    source = config.lib.file.mkOutOfStoreSymlink "/home/gl00m/dotfiles/config/caelestia";
  };
}
