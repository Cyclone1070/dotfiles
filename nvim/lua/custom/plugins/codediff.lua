return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	opts = {
		diff = {
			layout = "inline",
		},
		explorer = {
			initial_focus = "original",
		},
	},
	keys = {
		{ "<leader>dc", "<cmd>CodeDiff<cr>", desc = "Compare with clipboard" },
	},
}
