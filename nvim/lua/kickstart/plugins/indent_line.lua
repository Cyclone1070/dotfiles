return {
	{ -- Add indentation guides even on blank lines
		"lukas-reineke/indent-blankline.nvim",
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help ibl`
		main = "ibl",
		opts = {
			indent = {
				char = "▏",
				highlight = "IblIndent",
			},
			scope = {
				enabled = true,
			},
		},
		config = function(_, opts)
			vim.api.nvim_set_hl(0, "IblIndent", { fg = "#777777", nocombine = true })
			vim.api.nvim_set_hl(0, "IblScope", { fg = "#dddddd", nocombine = true })
			require("ibl").setup(opts)
		end,
	},
}
