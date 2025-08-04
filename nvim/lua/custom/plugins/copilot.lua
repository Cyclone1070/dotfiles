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
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		cmd = "CopilotChat",
		keys = {
			{
				"<leader>i",
				function()
					require("CopilotChat").toggle({
						context = { "files", "buffer:*" },
					})
				end,
				desc = "Toggle CopilotChat",
			},
		},
		opts = function()
			local user = vim.env.USER or "User"
			user = user:sub(1, 1):upper() .. user:sub(2)
			return {
				model = "claude-sonnet-4",
				mappings = {
					submit_prompt = {
						insert = "<C-CR>",
						normal = "<CR>",
					},

					reset = {
						normal = "<C-i>",
						insert = "<C-i>",
					},
				},
				question_header = "  " .. "Cyclone1070 ",
				answer_header = "  Copilot ",
				window = {
					layout = "float",
					border = "rounded",
					width = 0.7,
					height = 0.7,
				},
			}
		end,
		config = function(_, opts)
			local chat = require("CopilotChat")

			-- vim.api.nvim_create_autocmd("BufEnter", {
			-- 	pattern = "copilot-chat",
			-- 	callback = function()
			-- 		vim.opt_local.relativenumber = false
			-- 		vim.opt_local.number = false
			-- 	end,
			-- })

			chat.setup(opts)
		end,
	},
}
