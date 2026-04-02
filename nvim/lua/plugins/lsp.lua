-- setup lsp keymap
return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
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
          { "<leader>e", vim.diagnostic.open_float, desc = "Line Diagnostics" },

          -- jump between errors using <leader>l:
          {
            "<leader>lj",
            function()
              vim.diagnostic.jump({ count = 1, float = true })
            end,
            desc = "Next Diagnostic",
          },
          {
            "<leader>lk",
            function()
              vim.diagnostic.jump({ count = -1, float = true })
            end,
            desc = "Prev Diagnostic",
          },
        },
      },
    },
  },
}
