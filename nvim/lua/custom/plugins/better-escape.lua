return {
	"max397574/better-escape.nvim",
	opts = {
		timeout = 100,
		default_mappings = false,
		mappings = {
			-- i for insert
			i = {
				j = {
					-- These can all also be functions
					k = "<Esc>",
				},
				k = {
					j = "<Esc>",
				},
				J = {
					K = "<Esc>",
				},
				K = {
					J = "<Esc>",
				},
			},
			c = {
				j = {
					k = "<C-c>",
				},
				k = {
					j = "<C-c>",
				},
			},
			t = {
				j = {
					k = "<C-\\><C-n>",
				},
				k = {
					j = "<C-\\><C-n>",
				},
			},
			s = {
				j = {
					k = "<Esc>",
				},
				k = {
					j = "<Esc>",
				},
			},
		},
	},
}
