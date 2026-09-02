-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Ensure K scrolls up even when an LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set({ "n", "v" }, "K", "<C-u>", { buffer = args.buf, desc = "Scroll up" })
  end,
})
