return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        ghost_text = { enabled = false },
        menu = {
          border = "rounded", -- Options: "single", "double", "rounded", "solid", "shadow"
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
        },
        documentation = {
          window = {
            border = "rounded",
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
          },
        },
      },
      keymap = {
        preset = "none", -- Disable defaults to avoid Enter/Space conflicts

        -- Accept mappings
        ["<Tab>"] = { "accept", "fallback" },

        -- Navigation mappings
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },

        -- Useful defaults to keep
        ["<C-e>"] = { "hide", "fallback" },
      },
    },
  },
}
