return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint" },
      },
      linters = {
        markdownlint = {
          args = { "--disable", "MD013" }, -- Disables line length rule
        },
      },
    },
  },
}
