return {
	"echasnovski/mini.files",
	keys = {
		{
			"<leader>e",
			function()
				local miniFiles = require("mini.files")
				if not miniFiles.close() then
					miniFiles.open()
				end
			end,
			desc = "Open Files",
		},
	},
	config = function()
		-- toggle hidden files
		local show_dotfiles = false

		local filter_show = function(fs_entry)
			return true
		end

		local filter_hide = function(fs_entry)
			return not vim.startswith(fs_entry.name, ".")
		end
		
		require("mini.files").setup({
			content = {
				filter = filter_hide,
			},
		})

		local toggle_dotfiles = function()
			show_dotfiles = not show_dotfiles
			local new_filter = show_dotfiles and filter_show or filter_hide
			MiniFiles.refresh({ content = { filter = new_filter } })
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesBufferCreate",
			callback = function(args)
				local buf_id = args.data.buf_id
				-- You can change 'g.' to any key you like, e.g., '.' or 'H'
				vim.keymap.set("n", "H", toggle_dotfiles, { buffer = buf_id, desc = "Toggle dotfiles" })
			end,
		})
	end,
}
