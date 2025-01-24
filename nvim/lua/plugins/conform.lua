return {
    {
        "stevearc/conform.nvim",
        -- event = "BufWritePre", -- uncomment for format on save
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                css = { "prettier" },
                html = { "prettier" },
                python = { "isort", "black" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                svelte = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                markdown = { "prettier" },
            },
            formatters = {
                -- Python
                black = {
                    prepend_args = {
                        "--fast",
                        "--line-length",
                        "80",
                    },
                },
                isort = {
                    prepend_args = {
                        "--profile",
                        "black",
                    },
                },
                prettier = {
                    prepend_args = {
                        "--tab-width",
                        "4",
                    },
                },
            },

            -- format_on_save = {
            --     -- These options will be passed to conform.format()
            --     timeout_ms = 1000,
            --     lsp_fallback = true,
            -- },
        },
    },
}
