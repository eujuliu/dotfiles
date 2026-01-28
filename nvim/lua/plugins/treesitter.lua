return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    branch = "main",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-context",
        opts = {
          max_lines = 4,
          multiline_threshold = 2,
        },
      },
    },
    config = function()
      local ts = require("nvim-treesitter")
      local parsers = {
        "angular",
        "bash",
        "comment",
        "css",
        "scss",
        "diff",
        "dockerfile",
        "elixir",
        "git_config",
        "gitcommit",
        "gitignore",
        "groovy",
        "go",
        "heex",
        "hcl",
        "html",
        "http",
        "java",
        "javascript",
        "jsdoc",
        "json",
        "json5",
        "jsonc",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "python",
        "php",
        "regex",
        "rst",
        "rust",
        "scss",
        "ssh_config",
        "sql",
        "terraform",
        "typst",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }

      for _, parser in ipairs(parsers) do
        ts.install(parser)
      end

      vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo[0][0].foldmethod = "expr"
      vim.api.nvim_command("set nofoldenable")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = parsers,
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}
