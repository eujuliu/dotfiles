return {
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },

    version = "1.*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        documentation = { auto_show = false },
        menu = {
          winblend = vim.o.pumblend,
        },
      },

      signature = {
        enabled = true,
        window = {
          winblend = vim.o.pumblend,
        },
      },

      snippets = {
        preset = "luasnip"
      },

      sources = {
        default = { "snippets", "lsp", "path", "buffer" },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
}
