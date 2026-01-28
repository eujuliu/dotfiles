return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = {
          ensure_installed = {
            "js-debug-adapter",
            "biome",
            "lua-language-server",
            "selene",
            "luacheck",
            "shellcheck",
            "shfmt",
            "tailwindcss-language-server",
            "css-lsp",
            "phpcs",
            "php-cs-fixer",
            "vtsls",
            "angular-language-server",
            "intelephense",
            "emmet-ls"
          },
        },
        keys = {
          { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" }
        },
        ---@param opts MasonSettings | {ensure_installed: string[]}
        config = function(_, opts)
          require("mason").setup(opts)

          local installed_package_names = require('mason-registry').get_installed_package_names()
          for _, v in ipairs(opts.ensure_installed) do
            if not vim.tbl_contains(installed_package_names, v) then
              vim.cmd(":MasonInstall " .. v)
            end
          end

          -- local installed_packages = require("mason-registry").get_installed_packages()
          -- local installed_lsp_names = vim.iter(installed_packages):fold({}, function(acc, pack)
          --   table.insert(acc, pack.spec.neovim and pack.spec.neovim.lspconfig)
          --   return acc
          -- end)

        end,
      },
      "neovim/nvim-lspconfig",
    },
  },
}
