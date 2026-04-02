return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "none", -- Disable defaults to avoid Enter/Space conflicts

        -- Accept mappings
        ["<Tab>"] = { "accept", "fallback" },
        ["<C-l>"] = { "accept", "fallback" },

        -- Navigation mappings
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },

        -- Useful defaults to keep
        ["<C-e>"] = { "hide", "fallback" },
      },
    },
  },
}
