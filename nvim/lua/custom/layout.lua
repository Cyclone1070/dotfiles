-- use tab indent and set tab width to 4
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
-- set line wrap and break line at word end
vim.opt.wrap = true
vim.opt.linebreak = true
-- relative line numbers
vim.opt.relativenumber = true
-- termguicolors
vim.opt.termguicolors = true

--Neovide
if vim.g.neovide then -- Check if Neovim is running inside Neovide
	-- set font to comicshanns
	vim.opt.guifont = "JetBrainsMonoNL Nerd Font:h14"
	vim.g.neovide_hide_mouse_when_typing = true
	vim.g.neovide_cursor_vfx_mode = { "pixiedust" }
	vim.g.neovide_floating_shadow = false
end
-- Globally disable auto-continuation of comments on new lines for all filetypes
local myGlobalFormatOptionsGroup = vim.api.nvim_create_augroup("MyGlobalFormatOptions", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = myGlobalFormatOptionsGroup,
	pattern = "*",
	callback = function(args)
		if not args or not args.buf then
			return
		end

		local current_fo = vim.bo[args.buf].formatoptions

		if type(current_fo) ~= "string" then
			current_fo = ""
		end

		current_fo = string.gsub(current_fo, "r", "")
		current_fo = string.gsub(current_fo, "o", "")

		vim.bo[args.buf].formatoptions = current_fo
	end,
	desc = "Globally disable auto-continuation of comments on new lines for all filetypes",
})
