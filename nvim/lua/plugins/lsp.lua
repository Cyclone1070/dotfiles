return {
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local keys = require("lazyvim.plugins.lsp.keymaps").get()
            keys[#keys + 1] = { "<C-k>", false, mode = "i" }
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            diagnostics = {
                float = {
                    border = "rounded",
                },
            },
        },
    },
}
