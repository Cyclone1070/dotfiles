return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		-- Useful status updates for LSP.
		-- NOTE: `opts = {}` is the same as calling `require('j-hui/fidget.nvim').setup({})`
		-- { "j-hui/fidget.nvim", opts = {} },

		-- Allows extra capabilities provided by blink.cmp
		"saghen/blink.cmp",
		"nvim-java/nvim-java", -- Java LSP support
	},
	config = function()
		-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
		-- and elegantly composed help section, `:help lsp-vs-treesitter`

		--  This function gets run when an LSP attaches to a particular buffer.
		--    That is to say, every time a new file is opened that is associated with
		--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
		--    function will be executed to configure the current buffer
		--  This function wil not override server specific onattach
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				-- NOTE: Remember that Lua is a real programming language, and as such it is possible
				-- to define small helper and utility functions so you don't have to repeat yourself.
				--
				-- In this case, we create a function that lets us more easily define mappings specific
				-- for LSP related items. It sets the mode, buffer and description for us each time.
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				-- Rename the variable under your cursor.
				--  Most Language Servers support renaming across files, etc.
				map("<leader>lr", vim.lsp.buf.rename, "[L]sp [R]ename")

				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map("<leader>la", vim.lsp.buf.code_action, "[L]sp Code [A]ction", { "n", "x" })

				-- Add a mapping to organize imports and add missing ones.
				map("<leader>li", function()
					local bufnr = event.buf
					local filetype = vim.bo[bufnr].filetype
					local diagnostics = vim.diagnostic.get(bufnr)
					-- prevent react tags from importing twice
					local applied_actions = {}

					if not diagnostics or #diagnostics == 0 then
						print("No diagnostics found.")
						return
					end

					for _, d in ipairs(diagnostics) do
						local lsp_diagnostic = {
							range = {
								start = {
									line = d.lnum,
									character = d.col,
								},
								["end"] = {
									line = d.end_lnum or d.lnum,
									character = d.end_col or d.col,
								},
							},
							severity = d.severity,
							code = d.code,
							source = d.source,
							message = d.message,
						}
						local applied = false

						vim.lsp.buf.code_action({
							context = {
								diagnostics = { lsp_diagnostic },
							},
							range = {
								start = { d.lnum + 1, d.col + 1 },
								["end"] = { d.end_lnum + 1, d.end_col + 1 },
							},
							filter = function(action)
								if applied or applied_actions[action.title] then
									return false
								end
								-- Filter for actions that are likely to be "add import"
								if action.title:match("[Uu]pdate [Ii]mport") then
									applied = true
									applied_actions[action.title] = true
									return true
								elseif action.title:match("[Aa]dd [Ii]mport") then
									applied_actions[action.title] = true
									return true
								elseif filetype == "cs" and action.title:match("[Uu]sing") then
									applied_actions[action.title] = true
									return true
								elseif (filetype == "cpp") and action.title:match("^[Ii]nclude") then
									applied_actions[action.title] = true
									return true
								end
								return false
							end,
							apply = true,
						})
					end

					-- After attempting to add imports, organize them.
					local organize_params = {
						filter = function(action)
							-- Filter for actions that are likely to be "organize imports"
							return action.title:match("[Oo]rganize [Ii]mports")
						end,
						apply = true,
					}
					vim.defer_fn(function()
						vim.lsp.buf.code_action(organize_params)
					end, 100)
				end, "[L]sp Auto [I]mport")

				-- Find references for the word under your cursor.
				-- map("glr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
				--
				-- -- Jump to the implementation of the word under your cursor.
				-- --  Useful when your language has ways of declaring types without an actual implementation.
				-- map("gld", require("telescope.builtin").lsp_implementations, "[G]oto [D]eclaration")
				--
				-- -- -- Jump to the definition of the word under your cursor.
				-- -- --  This is where a variable was first declared, or where a function is defined, etc.
				-- -- --  To jump back, press <C-t>.
				-- -- map("gld", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				-- --
				-- -- -- WARN: This is not Goto Definition, this is Goto Declaration.
				-- -- --  For example, in C this would take you to the header.
				-- -- map("glD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				-- --
				-- -- Fuzzy find all the symbols in your current document.
				-- --  Symbols are things like variables, functions, types, etc.
				-- map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
				--
				-- -- Fuzzy find all the symbols in your current workspace.
				-- --  Similar to document symbols, except searches over your entire project.
				-- map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
				--
				-- -- Jump to the type of the word under your cursor.
				-- --  Useful when you're not sure what type a variable is and you want to see
				-- --  the definition of its *type*, not where it was *defined*.
				-- map("glt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
				-- Hover display
				map("r", vim.lsp.buf.hover, "Hove[R]")
				-- Diagnostic display
				map("<leader>ld", vim.diagnostic.open_float, "Hove[R]")

				-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
				---@param client vim.lsp.Client
				---@param method vim.lsp.protocol.Method
				---@param bufnr? integer some lsp support methods only in specific files
				---@return boolean
				local function client_supports_method(client, method, bufnr)
					if vim.fn.has("nvim-0.11") == 1 then
						return client:supports_method(method, bufnr)
					else
						return client.supports_method(method, { bufnr = bufnr })
					end
				end

				-- The following two autocommands are used to highlight references of the
				-- word under your cursor when your cursor rests there for a little while.
				--    See `:help CursorHold` for information about when this is executed
				--
				-- When you move your cursor, the highlights will be cleared (the second autocommand).
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if
					client
					and client_supports_method(
						client,
						vim.lsp.protocol.Methods.textDocument_documentHighlight,
						event.buf
					)
				then
					local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
						end,
					})
				end

				-- The following code creates a keymap to toggle inlay hints in your
				-- code, if the language server you are using supports them
				--
				-- This may be unwanted, since they displace some of your code
				if
					client
					and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
				then
					map("<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, "[T]oggle Inlay [H]ints")
				end
			end,
		})
		local should_import_on_save = true
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = vim.api.nvim_create_augroup("import-on-save", { clear = true }),
			callback = function(event)
				if not should_import_on_save then
					return
				end

				local bufnr = event.buf
				local filetype = vim.bo[bufnr].filetype

				local diagnostics = vim.diagnostic.get(bufnr)

				-- prevent react tags from importing twice
				local applied_actions = {}

				if not diagnostics or #diagnostics == 0 then
					print("No diagnostics found.")
					return
				end

				for _, d in ipairs(diagnostics) do
					local lsp_diagnostic = {
						range = {
							start = {
								line = d.lnum,
								character = d.col,
							},
							["end"] = {
								line = d.end_lnum or d.lnum,
								character = d.end_col or d.col,
							},
						},
						severity = d.severity,
						code = d.code,
						source = d.source,
						message = d.message,
					}
					local applied = false

					vim.lsp.buf.code_action({
						context = {
							diagnostics = { lsp_diagnostic },
						},
						range = {
							start = { d.lnum + 1, d.col + 1 },
							["end"] = { d.end_lnum + 1, d.end_col + 1 },
						},
						filter = function(action)
							if applied or applied_actions[action.title] then
								return false
							end
							-- Filter for actions that are likely to be "add import"
							if action.title:match("[Uu]pdate [Ii]mport") then
								applied = true
								applied_actions[action.title] = true
								return true
							elseif action.title:match("[Aa]dd [Ii]mport") then
								applied_actions[action.title] = true
								return true
							elseif filetype == "cs" and action.title:match("[Uu]sing") then
								applied_actions[action.title] = true
								return true
							end
							return false
						end,
						apply = true,
					})
				end

				-- After attempting to add imports, organize them.
				local organize_params = {
					filter = function(action)
						-- Filter for actions that are likely to be "organize imports"
						return action.title:match("[Oo]rganize [Ii]mports")
					end,
					apply = true,
				}
				vim.defer_fn(function()
					vim.lsp.buf.code_action(organize_params)
					vim.defer_fn(function()
						should_import_on_save = false
						vim.cmd.write()
						should_import_on_save = true
					end, 700)
				end, 100)
			end,
		})

		-- Diagnostic Config
		-- See :help vim.diagnostic.Opts
		vim.diagnostic.config({
			severity_sort = true,
			float = { border = "rounded", source = "if_many" },
			underline = { severity = vim.diagnostic.severity.ERROR },
			signs = vim.g.have_nerd_font and {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.INFO] = "󰋽 ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
				},
			} or {},
			virtual_text = {
				source = "if_many",
				spacing = 2,
				format = function(diagnostic)
					local diagnostic_message = {
						[vim.diagnostic.severity.ERROR] = diagnostic.message,
						[vim.diagnostic.severity.WARN] = diagnostic.message,
						[vim.diagnostic.severity.INFO] = diagnostic.message,
						[vim.diagnostic.severity.HINT] = diagnostic.message,
					}
					return diagnostic_message[diagnostic.severity]
				end,
			},
		})

		-- LSP servers and clients are able to communicate to each other what features they support.
		--  By default, Neovim doesn't support everything that is in the LSP specification.
		--  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
		--  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
		local capabilities = require("blink.cmp").get_lsp_capabilities()
		-- load the lsp table from custom/lsp.lua
		local servers_status, servers_to_configure = pcall(require, "custom.lsp")
		if not servers_status or type(servers_to_configure) ~= "table" then
			vim.notify(
				"LSP: Could not load server configurations from custom.lsp. No LSPs will be set up.",
				vim.log.levels.WARN
			)
			servers_to_configure = {}
		end

		-- REMOVE: local lspconfig_instance = require('lspconfig') -- Not needed for setup in this new way

		-- setup nvim-java
		require("java").setup({
			java_debug_adapter = {
				enable = false,
			},
		})
		require("lspconfig").jdtls.setup({})

		-- setup the rest of the lsp
		for server_name, user_server_config in pairs(servers_to_configure) do
			if type(user_server_config) == "table" then
				local server_opts = vim.deepcopy(user_server_config)

				-- Apply global capabilities, allowing server-specific ones to override
				server_opts.capabilities =
					vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})

				-- Configure the server using Neovim's core LSP config function.
				-- nvim-lspconfig makes its default configurations available through this.
				vim.lsp.config(server_name, server_opts)

				-- Enable the server. This tells Neovim to activate this LSP for relevant filetypes.
				-- No need to check lspconfig_instance.configs anymore.
				-- If nvim-lspconfig provides a config for server_name, vim.lsp.enable will use it
				-- along with your overrides from vim.lsp.config().
				local success, err = pcall(vim.lsp.enable, server_name)
				if not success then
					vim.notify(
						"LSP: Failed to enable server '"
							.. server_name
							.. "'. Error: "
							.. tostring(err)
							.. ". Ensure '"
							.. server_name
							.. "' is a valid LSP name provided by nvim-lspconfig or defined via vim.lsp.config().",
						vim.log.levels.WARN
					)
				end
			else
				vim.notify(
					"LSP: Configuration for server '" .. server_name .. "' in custom.lsp is not a table. Skipping.",
					vim.log.levels.WARN
				)
			end
		end
	end,
}
