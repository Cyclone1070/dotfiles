return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      on_colors = function(colors)
        colors.bg_statusline = colors.none -- This specifically makes the bar transparent
      end,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
}
