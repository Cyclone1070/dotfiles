return {
	"pmizio/typescript-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	opts = {
		settings = {
			expose_as_code_action = { "organize_imports" },
			-- other settings...
		},
	},
}
