return {
	"nvim-treesitter/nvim-treesitter-context",
	dependencies = {
		-- default comment toggle keymap (gc) is unmapped in mini.nvim setup so need to run that file first to free up the keymap
		"echasnovski/mini.nvim",
	},
	config = function()
		vim.keymap.set("n", "gc", function()
			require("treesitter-context").go_to_context(vim.v.count1)
		end, { silent = true, desc = "[G]o to [C]ontext" })
	end,
}
