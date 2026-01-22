return {
  {
    "stevearc/conform.nvim",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "x" },
        desc = "Format Injected Langs",
      },
    },
    opts = function()
      ---@type conform.setupOpts

      local js = { "biome", "prettierd", "prettier", stop_after_first = true }

      local opts = {
        formatters_by_ft = {
          lua = { "stylua" },
          fish = { "fish_indent" },
          sh = { "shfmt" },
          xml = { "xmlformat" },
          svg = { "xmlformat" },
          javascript = js,
          typescript = js,
        },
        formatters = {
          injected = { options = { ignore_errors = true } },
          biome = {
            require_cwd = true,
          },
        },
        default_format_opts = {
          timeout_ms = 3000,
          async = false,
          quiet = false,
          lsp_format = "fallback",
        },
      }

      return opts
    end,
  },
}
