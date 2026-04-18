return {
  -- 1. Configure copilot.lua for ghost text (Suggestions)
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        enabled = true, -- Enable the ghost text
        auto_trigger = true, -- Show suggestions as you type
        keymap = {
          accept = "<C-l>", -- Map C-l to accept copilot suggestion
        },
      },
      panel = { enabled = false },
    },
  },

  -- 2. Remove Copilot from the blink.cmp menu
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- Filter out the copilot provider from the default sources
      opts.sources.default = vim.tbl_filter(function(source)
        return source ~= "copilot"
      end, opts.sources.default or {})
    end,
  },
}
