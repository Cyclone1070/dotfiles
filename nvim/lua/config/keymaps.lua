-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
map("n", ";", ":", { desc = "CMD enter command mode" })
-- remap escape to jk or kj
map("i", "jk", "<ESC>", { noremap = true, silent = true })
map("i", "kj", "<ESC>", { noremap = true, silent = true })
map("i", "JK", "<ESC>", { noremap = true, silent = true })
map("i", "KJ", "<ESC>", { noremap = true, silent = true })
-- only paste from yank register
map("n", "p", '"0p')
-- diagnostics shortcut
map("n", "<leader>i", function()
    vim.diagnostic.open_float()
end, { desc = "Show diagnostic under cursor" })
-- noice.vim dismiss notification
map("n", "<leader>n", function()
    require("noice").cmd("dismiss")
end, { desc = "Dismiss All Notifications" })
-- remap go to end of line
map("n", "E", "$")
map("v", "E", "$")
-- remap go to start of line
map("n", "B", "^")
map("v", "B", "^")
-- Move cursor in insert mode
map("i", "<C-h>", "<Left>", { desc = "Move cursor left" })
map("i", "<C-l>", "<Right>", { desc = "Move cursor right" })
map("i", "<C-j>", "<Down>", { desc = "Move cursor down" })
map("i", "<C-k>", "<Up>", { desc = "Move cursor up" })
-- trigger conform
map("n", "<leader>fm", function()
    require("conform").format()
end, { desc = "Format document" })
-- open file explorer
map("n", "<C-n>", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
