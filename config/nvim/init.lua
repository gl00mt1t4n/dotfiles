vim.g.mapleader = " "

vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.termguicolors  = true
vim.opt.signcolumn     = "yes"
vim.opt.expandtab      = true
vim.opt.shiftwidth     = 2
vim.opt.tabstop        = 2

require("catppuccin").setup({ flavour = "mocha" })
vim.cmd.colorscheme("catppuccin")

require("bufferline").setup({})

require("nvim-tree").setup({
  view = { width = 30 },
})

local map = function(k, v) vim.keymap.set("n", k, v, { silent = true }) end
map("<leader>e",  ":NvimTreeToggle<CR>")
map("<Tab>",      ":BufferLineCycleNext<CR>")
map("<S-Tab>",    ":BufferLineCyclePrev<CR>")
map("<leader>q",  ":bdelete<CR>")
