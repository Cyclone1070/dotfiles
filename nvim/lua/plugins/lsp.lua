-- setup lsp keymap
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ["*"] = {
        keys = {
          -- add a new keymap
          {
            "r",
            function()
              return vim.lsp.buf.hover()
            end,
            desc = "Custom Hover",
          },
          -- Disable a keymap
          { "K", false },
          { "<leader>cr", false },
          { "<leader>ca", false },
          { "gK", false },
          { "gy", false },

          -- 2. Map them under <leader>l
          { "<leader>lr", vim.lsp.buf.rename, desc = "Rename" },
          { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" } },
          { "<leader>ls", vim.lsp.buf.signature_help, desc = "Signature Help" },
          { "gt", vim.lsp.buf.type_definition, desc = "Go To [T]ype Definition" },
        },
      },
    },
  },
}
