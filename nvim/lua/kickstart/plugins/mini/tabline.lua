return {
	"echasnovski/mini.tabline",
	config = function()
		require("mini.tabline").setup()
		vim.keymap.set("n", "H", "<CMD>bNext<CR>")
		vim.keymap.set("n", "L", "<CMD>bnext<CR>")
		vim.keymap.set("n", "<leader>w", "<CMD>bd<CR>")
		if vim.g.neovide then
			vim.keymap.set("n", "<D-w>", "<CMD>bd<CR>")
		end
	end,
}
