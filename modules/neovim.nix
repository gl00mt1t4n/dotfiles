{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvim-tree-lua
      nvim-web-devicons
      bufferline-nvim
      catppuccin-nvim
    ];
    extraLuaConfig = builtins.readFile ../config/nvim/init.lua;
  };
}
