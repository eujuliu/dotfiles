return {
  {
    "datsfilipe/min-theme.nvim",
    priority = 1000,
    config = function()
      local theme

      if vim.env.THEME == "prefer-dark" then
        theme = "dark"
      else
        theme = "light"
      end

      vim.opt.background = theme

      require("min-theme").setup({
        theme = theme,
        transparent = true,
      })

      vim.cmd.colorscheme("min-theme")
    end,
  },
}
