return {
	{ "echasnovski/mini.colors", opts = {} },
	{
		"echasnovski/mini.hues",
		priority = 1000, -- Make sure to load this before all the other start plugins.
		config = function()
			local hues = require("mini.hues")

			-- Define the custom function to generate hues, avoiding pinks and reds
			local function generate_allowed_hue()
				-- Define the hue range to ALLOW (inclusive)
				-- This excludes reds (0-15) and pinks/pink-reds (310-359)
				local min_allowed_hue = 16 -- Start after red, in orange territory
				local max_allowed_hue = 309 -- Stop before pink/magenta territory

				-- Directly generate a random hue within the allowed range
				local hue = math.random(min_allowed_hue, max_allowed_hue)
				-- Return the allowed hue
				return hue
			end
			local function set_additional_highlight()
				-- Set additional highlights
				-- constructing line number highlight style by combining fg with bg of cursorline
				local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
				local line_nr_bg = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).bg
				-- constructing tabline colors to keep their default and only append bg
				local tabline_current = vim.api.nvim_get_hl(0, { name = "MiniTablineCurrent", link = false })
				tabline_current.bg = vim.api.nvim_get_hl(0, { name = "Visual", link = false }).bg
				local tabline_hidden = vim.api.nvim_get_hl(0, { name = "MiniTablineHidden", link = false })
				tabline_hidden.bg = line_nr_bg
				local tabline_trunc = vim.api.nvim_get_hl(0, { name = "MiniTablineTrunc", link = false })
				tabline_trunc.bg = line_nr_bg

				-- Set the entire left column to new style
				vim.api.nvim_set_hl(0, "LineNr", { fg = "#788a8a", bg = line_nr_bg })
				vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#bbbbbb", bg = line_nr_bg })
				vim.api.nvim_set_hl(0, "SignColumn", { fg = "#788a8a", bg = line_nr_bg })
				vim.api.nvim_set_hl(0, "CursorLineSign", { fg = "#788a8a", bg = line_nr_bg })
				-- Set minitabline color
				vim.api.nvim_set_hl(0, "MiniTablineCurrent", tabline_current)
				vim.api.nvim_set_hl(0, "MiniTablineVisible", { link = "MiniTablineHidden" })
				vim.api.nvim_set_hl(0, "MiniTablineHidden", tabline_hidden)
				vim.api.nvim_set_hl(0, "MiniTablineTrunc", tabline_trunc)
				-- Keywords highlight
				vim.api.nvim_set_hl(0, "Statement", { fg = "#E1914C" })
				-- Blink cmp ghost text
				vim.api.nvim_set_hl(0, "BlinkCmpGhostText", { link = "Comment" })
			end

			-- function to be called in colorscheme
			function _G.load_initial_random_hues()
				-- Use os.time() for broader compatibility during early startup
				math.randomseed(math.floor(vim.fn.reltimefloat(vim.fn.reltime()) * 1000000))

				-- Generate the base colors using our custom hue generator
				local base_colors = hues.gen_random_base_colors({
					gen_hue = generate_allowed_hue,
				})
				-- Setup mini.hues with the generated colors.
				hues.setup(base_colors)
				set_additional_highlight()
			end

			-- enable colorscheme
			vim.cmd.colorscheme("minirandom")

			-- autocmd to change color on buffer change
			-- get the hue animation steps
			local function generate_hue_transition_steps()
				-- get the current hue
				local miniColors = require("mini.colors")
				local normal_bg_hex =
					string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg)
				local normal_bg_oklch = miniColors.convert(normal_bg_hex, "oklch")

				if normal_bg_oklch == nil then
					return "no current hue"
				end

				local old_hue = math.floor(normal_bg_oklch.h + 0.5)
				local new_hue = generate_allowed_hue()

				while new_hue == old_hue do
					new_hue = generate_allowed_hue()
				end

				local step = (new_hue - old_hue) / 16

				local transition_hues = {}
				for current_hue = old_hue, new_hue, step do
					table.insert(transition_hues, math.floor(current_hue + 0.5))
				end
				return transition_hues
			end
			local is_animating = false
			local is_neon = false
			-- animate function to put inside autocmd callback
			local function animate_scheme(delay_per_item_ms)
				if is_animating then
					return
				end

				is_animating = true
				local my_hues = generate_hue_transition_steps()
				-- local delay_per_item_ms = 25

				for i, current_hue in ipairs(my_hues) do
					local current_delay_ms = (i - 1) * delay_per_item_ms

					vim.defer_fn(function()
						local base_colors = hues.gen_random_base_colors({
							gen_hue = function()
								return current_hue
							end,
						})
						hues.setup(base_colors)
						set_additional_highlight()
						if i == #my_hues then
							is_animating = false
							if is_neon then
								animate_scheme(400)
							end
						end
					end, current_delay_ms)
				end
			end
			-- Create a user command to toggle neon animation
			local function toggle_neon()
				is_neon = not is_neon
				if is_neon and not is_animating then
					animate_scheme(400)
				end
			end
			vim.api.nvim_create_user_command("Neon", toggle_neon, {
				nargs = 0,
				desc = "Toggle neon color scheme animation",
			})

			local last_file_bufnr
			local myBufferEventsGroup = vim.api.nvim_create_augroup("MyBufferEventActions", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter" }, {
				group = myBufferEventsGroup,
				pattern = "*", -- Apply to all buffers/filetypes. Adjust if needed.
				callback = function(args)
					local bufnr = args.buf
					-- on first load
					if not last_file_bufnr then
						last_file_bufnr = bufnr
						return
					end

					-- Filter for "normal" file buffers
					-- buflisted(bufnr) == 1: Is it a user-interactable buffer?
					-- vim.bo[bufnr].buftype == "": Is it a normal buffer (not 'nofile', 'prompt', 'help', etc.)?
					if
						vim.fn.bufexists(bufnr) == 1
						and vim.fn.buflisted(bufnr) == 1
						and vim.bo[bufnr].buftype == ""
						and last_file_bufnr ~= bufnr
					then
						last_file_bufnr = bufnr
						animate_scheme(25)
					end
				end,
			})
		end,
	},
}
