-- Linters configuration
-- The keys are filetypes, values are arrays of linter names as expected by nvim-lint
local linters = {
	dockerfile = { "hadolint" },
	json = { "jsonlint" },
	go = { "golangcilint" }, -- nvim-lint expects "golangcilint" (no hyphen)
}

-- Mapping from nvim-lint linter names to Mason package names
-- Only needed when the names differ
local linter_to_mason = {
	golangcilint = "golangci-lint", -- Mason package has hyphen
}

return {
	linters = linters,
	linter_to_mason = linter_to_mason,
}
