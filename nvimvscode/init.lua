local map = vim.keymap.set
local opts = { noremap = true, silent = true }
--remap leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- enter command remap
map("n", ";", ":")
-- remap go to end of line
map("n", "E", "$")
map("v", "E", "$")
map("v", "B", "^")
-- remap go to start of line
map("n", "B", "^")
-- remap tab
vim.cmd("nmap H gT")
vim.cmd("nmap L gt")
-- switch panel
vim.cmd("nmap <C-h> <C-w>h")
vim.cmd("nmap <C-l> <C-w>l")
-- move cursor in insert mode
map("i", "<C-h>", "<Left>")
map("i", "<C-j>", "<Down>")
map("i", "<C-k>", "<Up>")
map("i", "<C-l>", "<Right>")