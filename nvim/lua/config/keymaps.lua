-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
local opts = { noremap = true }

local del = vim.keymap.del

del("n", "<leader>l")
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
map("n", "<Esc>", function()
  vim.cmd("nohlsearch")
  local char = require("flash.plugins.char")
  if char.state then
    char.state:hide()
  end
end, { desc = "Clear highlights" })

-- Diagnostic keymaps
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- aditional keymaps here

-- enter command mode with ;
map({ "n", "v" }, ";", ":", opts)

-- leader w to save
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save File", noremap = true })

-- mapping for search and replace
map("n", "<leader>r", ":%s/", { desc = "Search and Replace", noremap = true })
map("v", "<leader>r", ":s/", { desc = "Search and Replace in Selection", noremap = true })

-- remap v to exit visual mode
map("v", "v", "<ESC>")

-- only paste from yank register
map("n", "p", '"0p')
map("n", "P", '"0P')

-- diagnostics shortcut
map("n", "<leader>i", function()
  vim.diagnostic.open_float()
end, { desc = "Show diagnostic under cursor" })

-- remap go to end of line
map({ "n", "o", "v" }, "E", "$", opts)

-- remap go to start of line
map({ "n", "o", "v" }, "B", "^", opts)

-- move current window around
map("n", "<C-w>h", "<C-w>H", { desc = "Move window left" })
map("n", "<C-w>j", "<C-w>J", { desc = "Move window down" })
map("n", "<C-w>k", "<C-w>K", { desc = "Move window up" })
map("n", "<C-w>l", "<C-w>L", { desc = "Move window right" })
map("n", "<C-w><CR>", "<C-w>_<C-w>|", { desc = "Maximize window" })

-- buffer mappings
map("n", "L", "<C-^>", { desc = "Go to last used buffer" })
map("n", "<leader>x", "<cmd>bd<CR>", { desc = "Close current buffer" })

-- scroll
map({ "n", "v" }, "J", "<C-d>", { desc = "Scroll down" })
map({ "n", "v" }, "K", "<C-u>", { desc = "Scroll up" })

-- C-J and C-K to merge lines
map("n", "<leader>j", "J", opts)
map("n", "<leader>k", "K", opts)

-- Keep Visual mode active after indent/unindent
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Map move lines
map("n", "<M-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<M-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<M-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<M-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<M-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<M-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- fold until matching pairs
map("n", "Z", "zf%", { desc = "Fold until matching pairs" })

-- format
map("n", "<leader>f", function()
  LazyVim.format({ force = true })
end)
