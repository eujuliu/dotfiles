return {
  {
    "datsfilipe/min-theme.nvim",
    priority = 1000,
    opts = {
      transparent = true,
    },
    config = function(_, opts)
      require("min-theme").setup(opts)
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "min-theme",
    },
  },
}
