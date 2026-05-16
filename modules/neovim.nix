{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
    plugins = with pkgs.vimPlugins; [
      nvim-tree-lua
      nvim-web-devicons
      bufferline-nvim
      catppuccin-nvim
    ];
    initLua = builtins.readFile ../config/nvim/init.lua;
  };
}
