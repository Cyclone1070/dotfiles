local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- remap for escape visual mode
map("v", "v", "<Esc>", opts)
-- enter command remap
map("n", ";", ":", opts)
-- remap go to end of line
map("n", "E", "$", opts)
map("v", "E", "$", opts)
-- remap go to start of line
map("v", "B", "^", opts)
map("n", "B", "^", opts)
-- remap pressing space to get hover info
map("n", " ", vim.lsp.buf.hover, opts)
-- remap for faster scrolling
map("n", "J", "5j", opts)
map("n", "K", "5k", opts)
map("v", "J", "5j", opts)
map("v", "K", "5k", opts)
-- remap tab
vim.cmd("nmap H gT")
vim.cmd("nmap L gt")
-- switch panel
vim.cmd("nmap <C-h> <C-w>h")
vim.cmd("nmap <C-l> <C-w>l")
-- move cursor in insert mode
map("i", "<C-h>", "<Left>", opts)
map("i", "<C-j>", "<Down>", opts)
map("i", "<C-k>", "<Up>", opts)
map("i", "<C-l>", "<Right>", opts)