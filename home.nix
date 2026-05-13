{ lib, pkgs, ... };

{
home = {
packages = with pkgs; [
hello
];

username = "gl00m";
homeDirectory = "/home/gl00m";

stateVersion = "23.11";
}

programs.bash = {
enable = true;
};
programs.kitty.enable = true;
wayland.windowManager.hyprland.enable - true;
}
