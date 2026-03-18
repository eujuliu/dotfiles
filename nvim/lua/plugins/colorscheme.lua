return {
  {
    "datsfilipe/min-theme.nvim",
    priority = 1000,
    config = function()
      local handle = io.popen(
        "gsettings get org.gnome.desktop.interface color-scheme"
      )

      if not handle then
        vim.notify("Could not read GNOME theme", vim.log.levels.ERROR)
        return
      end

      local result = handle:read("*a")
      handle:close()

      local theme = result and result:match("dark") and "dark" or "light"
      vim.opt.background = theme

      require("min-theme").setup({
        theme = theme,
        transparent = true,
      })

      vim.cmd.colorscheme("min-theme")
    end,
  },
}
