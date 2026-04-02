-- Automated CodeDiff LSP Diagnostic
-- This file will automatically log what changes before/after CodeDiff

local log_file = vim.fn.stdpath("data") .. "/codediff-lsp-debug.log"
local M = {}

local function log(msg)
	local file = io.open(log_file, "a")
	if file then
		file:write(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. msg .. "\n")
		file:close()
	end
end

local function capture_state(label)
	log("========== " .. label .. " ==========")
	
	local buf = vim.api.nvim_get_current_buf()
	log("Buffer: " .. buf .. " | Name: " .. vim.api.nvim_buf_get_name(buf))
	log("Buftype: " .. vim.bo[buf].buftype .. " | Filetype: " .. vim.bo[buf].filetype)
	
	-- Check LSP clients
	local clients = vim.lsp.get_clients({ bufnr = buf })
	if #clients == 0 then
		log("❌ NO LSP CLIENTS attached to buffer")
	else
		for _, client in ipairs(clients) do
			log("✅ LSP Client attached: " .. client.name .. " (id: " .. client.id .. ")")
		end
	end
	
	-- Check all LSP clients globally
	local all_clients = vim.lsp.get_clients()
	log("Total active LSP clients globally: " .. #all_clients)
	for _, client in ipairs(all_clients) do
		local attached_bufs = vim.tbl_keys(client.attached_buffers or {})
		log("  - " .. client.name .. " attached to " .. #attached_bufs .. " buffers")
	end
	
	-- Check 'r' keymap
	local keymaps = vim.api.nvim_buf_get_keymap(buf, "n")
	local found_r = false
	for _, keymap in ipairs(keymaps) do
		if keymap.lhs == "r" then
			found_r = true
			log("✅ 'r' keymap exists (buffer-local)")
		end
	end
	if not found_r then
		log("❌ 'r' keymap NOT FOUND (buffer-local)")
	end
	
	-- Check hover functionality
	local hover_supported = false
	for _, client in ipairs(clients) do
		if client.server_capabilities.hoverProvider then
			hover_supported = true
			log("✅ Hover supported by " .. client.name)
		end
	end
	if not hover_supported and #clients > 0 then
		log("❌ Hover NOT supported by any attached client")
	end
	
	log("")
end

-- Clear log file on Neovim start
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local file = io.open(log_file, "w")
		if file then
			file:write("=== CodeDiff LSP Diagnostic Log ===\n")
			file:write("Started at: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
			file:close()
		end
		log("Diagnostic logger initialized")
		log("Log file: " .. log_file)
		log("")
	end,
})

-- Hook into LspAttach to capture initial state
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		log("LspAttach event fired for buffer " .. args.buf)
		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(args.buf) then
				local current_buf = vim.api.nvim_get_current_buf()
				if current_buf == args.buf then
					capture_state("AFTER LspAttach (buffer " .. args.buf .. ")")
				end
			end
		end, 100)
	end,
})

-- Hook into CodeDiff events
vim.api.nvim_create_autocmd("User", {
	pattern = "CodeDiffOpen",
	callback = function()
		log("🔵 CodeDiffOpen event fired")
		vim.defer_fn(function()
			capture_state("AFTER CodeDiff OPENED")
		end, 200)
	end,
})

-- Helper function to force LSP resync by sending full document change
local function force_lsp_resync(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	
	-- Get all LSP clients attached to this buffer
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if not clients or #clients == 0 then
		log("  No LSP clients attached to buffer " .. bufnr)
		return
	end
	
	for _, client in ipairs(clients) do
		if client and not client.is_stopped() then
			log("  🔄 Forcing full document sync for " .. client.name .. " (id: " .. client.id .. ")")
			
			-- The key to fixing the incremental didChange desync bug is to:
			-- 1. Get the ACTUAL buffer content
			-- 2. Send it as a FULL document replacement (no range = full replacement)
			-- This bypasses the buggy incremental change tracking in Neovim
			
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end
				
				local uri = vim.uri_from_bufnr(bufnr)
				if not uri then
					return
				end
				
				-- Get the buffer's ACTUAL current content
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				local text = table.concat(lines, "\n")
				
				-- Neovim convention: if buffer has content and doesn't end with newline, we don't add it
				-- But LSP expects files to end with newline, so add it if needed
				if #lines > 0 and lines[#lines] ~= "" then
					text = text .. "\n"
				elseif #lines == 0 then
					text = "" -- Empty file
				end
				
				-- Send full document didChange
				-- Note: omitting the 'range' field indicates full document replacement
				local params = {
					textDocument = {
						uri = uri,
						version = vim.fn.getbufvar(bufnr, "changedtick", 0),
					},
					contentChanges = {
						{
							text = text,
							-- NO 'range' field = full document replacement per LSP spec
						}
					}
				}
				
				-- Send the notification to the LSP server
				client.notify("textDocument/didChange", params)
				log("    ✅ Full document sync notification sent to " .. client.name)
			end)
		end
	end
end

vim.api.nvim_create_autocmd("User", {
	pattern = "CodeDiffClose",
	callback = function()
		log("🔴 CodeDiffClose event fired")
		vim.defer_fn(function()
			capture_state("AFTER CodeDiff CLOSED")
			
			-- FIX: Force LSP clients to resync with full document
			-- CodeDiff (in inline mode) modifies buffer content via nvim_buf_set_lines(),
			-- which causes incremental didChange notifications to desynchronize gopls
			-- due to a Neovim LSP bug. We fix this by sending a full document sync.
			log("🔧 APPLYING LSP FIX: Forcing full document resync")
			
			local buf = vim.api.nvim_get_current_buf()
			force_lsp_resync(buf)
			
			vim.defer_fn(function()
				capture_state("AFTER LSP RESYNC")
			end, 500)
		end, 300)
	end,
})

-- Create a command to manually capture state
vim.api.nvim_create_user_command("CodeDiffDebug", function()
	capture_state("MANUAL CAPTURE")
	print("State captured! View log: " .. log_file)
end, {})

-- Create a command to view the log
vim.api.nvim_create_user_command("CodeDiffDebugLog", function()
	vim.cmd("edit " .. log_file)
end, {})

-- Create a command to test hover
vim.api.nvim_create_user_command("CodeDiffTestHover", function()
	log("Testing hover manually...")
	local before = vim.fn.winbufnr(vim.fn.winnr())
	vim.lsp.buf.hover()
	
	vim.defer_fn(function()
		local after = vim.fn.winbufnr(vim.fn.winnr())
		if before ~= after then
			log("✅ Hover opened a new window")
		else
			log("❌ Hover did not open a window (might show 'no information available')")
		end
	end, 500)
end, {})

log("Diagnostic module loaded. Commands available:")
log("  :CodeDiffDebug - Manually capture current state")
log("  :CodeDiffDebugLog - View the debug log")
log("  :CodeDiffTestHover - Test hover functionality")
log("🎯 NOTE: Hover calls are logged automatically when you press 'r'")
log("")

-- Return empty table to avoid plugin spec errors
return {}
