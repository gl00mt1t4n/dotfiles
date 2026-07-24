{ pkgs, ... }:
{
  # Put normal user-facing apps here.
  #
  # Rule of thumb:
  # - Steam games are NOT listed here. Install them inside Steam; they live under
  #   ~/.local/share/Steam and use Steam/Proton normally.
  # - AppImages from the web can be launched with appimage-run or installed with
  #   the appimage-install helper from home.nix.
  # - Drivers, services, users, boot, Steam itself, and hardware support belong
  #   in configuration.nix.
  home.packages = with pkgs; [
    # Daily GUI apps
    kitty
    firefox
    zen-browser
    brave
    telegram-desktop
    vesktop
    pavucontrol
    qpwgraph

    # Desktop helpers
    zenity
    brightnessctl
    libnotify
    playerctl
    lxqt.lxqt-policykit
    networkmanagerapplet
    iw
    appimage-run

    # Gaming diagnostics/wrappers. Steam installs games itself; these help run
    # and measure them cleanly on Wayland/HiDPI.
    gamescope
    mangohud
    protonup-qt

    # Agent/AI tools
    claude-code

    # Fonts/themes/icons
    inter
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.meslo-lg
    catppuccin-gtk
    papirus-icon-theme
    catppuccin-cursors.mochaDark

    # CLI tools
    git
    jq
    alsa-utils
    pamixer
  ];
}
