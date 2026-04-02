return {
  {
    "folke/noice.nvim",
    keys = {
      { "<leader>n", "<cmd>Noice dismiss<CR>" },
    },

    opts = {
      presets = {
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
  },
}
