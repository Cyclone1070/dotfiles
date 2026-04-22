-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Diagnostic styling
vim.diagnostic.config({
  float = {
    border = "rounded", -- Options: "single", "double", "rounded", "solid", "shadow"
    header = "", -- Optional: removes the "Diagnostics:" header for a cleaner look
  },
})

-- Indent
opt.shiftwidth = 4 -- Size of an indent
opt.tabstop = 4 -- Number of spaces tabs count for
opt.softtabstop = 4 -- Number of spaces tabs count for while editing
opt.expandtab = true -- Use spaces instead of tabs

-- linewrap
vim.opt.wrap = true
