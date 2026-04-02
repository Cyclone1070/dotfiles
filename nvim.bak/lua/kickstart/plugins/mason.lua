-- setting up table of tools for mason to install
local lsp = vim.tbl_keys(require("custom.lsp"))
local formatters = require("custom.formatters")
local linters_config = require("custom.linters")
local linters = linters_config.linters
local linter_to_mason = linters_config.linter_to_mason

local function get_unique_strings_from_table(input_table)
	local result_array = {}
	local seen_strings = {} -- Helper table to track unique strings

	-- Iterate through the main table (e.g., {python = ..., lua = ...})
	for _, inner_table in pairs(input_table) do
		-- Check if the inner value is actually a table
		if type(inner_table) == "table" then
			-- Iterate through the inner array (e.g., {"black", "isort"})
			for _, str_value in ipairs(inner_table) do
				-- Check if the string has been seen before
				if type(str_value) == "string" and not seen_strings[str_value] then
					table.insert(result_array, str_value)
					seen_strings[str_value] = true -- Mark string as seen
				end
			end
		end
	end

	return result_array
end

-- Map linter names to Mason package names
local function map_linters_to_mason(linter_list, mapping_table)
	local result = {}
	for _, linter_name in ipairs(linter_list) do
		-- Use the mapped name if it exists, otherwise use the linter name as-is
		local mason_name = mapping_table[linter_name] or linter_name
		table.insert(result, mason_name)
	end
	return result
end

-- find unique values
local unique_formatters = get_unique_strings_from_table(formatters)
local unique_linters = get_unique_strings_from_table(linters)
local unique_linters_mason = map_linters_to_mason(unique_linters, linter_to_mason)

-- final table with tools to install
local all_packages = {}
table.move(lsp, 1, #lsp, 1, all_packages)
table.move(unique_formatters, 1, #unique_formatters, #all_packages + 1, all_packages)
table.move(unique_linters_mason, 1, #unique_linters_mason, #all_packages + 1, all_packages)

return {
	-- setup mason engine, required
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {
			registries = {
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			},
			ui = {
				-- border and icons
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	-- setup auto installation, require mason-lspconfig for package namings compatibility
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = {
			"mason-org/mason-lspconfig.nvim",
		},
		config = function()
			if #all_packages > 0 then
				require("mason-tool-installer").setup({
					ensure_installed = all_packages,
				})
			end
		end,
	},
}
