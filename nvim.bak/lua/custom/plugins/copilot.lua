return {
	{
		"zbirenbaum/copilot.lua",
		event = "InsertEnter",
		cmd = "Copilot",
		opts = {
			suggestion = {
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = false,
					accept_word = false, -- Disable accepting word suggestions
					accept_line = false, -- Disable accepting line suggestions
				},
			},
			panel = {
				auto_refresh = true,
			},
			filetypes = {
				["*"] = true, -- Enable Copilot for all file types
			},
		},
		config = function(_, opts)
			require("copilot").setup(opts)
		end,
	},
}
