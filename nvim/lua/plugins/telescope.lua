return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-telescope/telescope-file-browser.nvim",
      { "nvim-tree/nvim-web-devicons", opts = {} },
    },
    keys = {
      -- git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>",         desc = "Commits" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>",          desc = "Status" },
      { "<leader>gS", "<cmd>Telescope git_stash<cr>",           desc = "Git Stash" },
      -- search
      { "<leader>sd", "<cmd>Telescope diagnostics<cr>",         desc = "Diagnostics" },
      { "<leader>sD", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Buffer Diagnostics" },
      {
        "sr",
        function()
          local builtin = require("telescope.builtin")
          builtin.live_grep({
            additional_args = { "--hidden" },
          })
        end,
        desc =
        "Search for a string in your current working directory",
      },
      {
        "<leader>sn",
        function()
          local builtin = require("telescope.builtin")
          builtin.treesitter()
        end,
        desc = "Lists Function names, variables",
      },

      {
        "<leader><space>",
        function()
          local telescope = require("telescope")

          telescope.extensions.file_browser.file_browser({
            path = vim.loop.cwd(),
            cwd = vim.loop.cwd(),
            respect_gitignore = false,
            grouped = true,
            hidden = true,
            no_ignore = true,
            initial_mode = "normal",
            -- layout_config = { height = 40 },
          })
        end,
        desc = "Open File Browser in current working directory",
      },
      {
        "sf",
        function()
          local telescope = require("telescope")

          local function telescope_buffer_dir()
            return vim.fn.expand("%:p:h")
          end

          telescope.extensions.file_browser.file_browser({
            path = "%:p:h",
            cwd = telescope_buffer_dir(),
            respect_gitignore = false,
            grouped = true,
            hidden = true,
            no_ignore = true,
            initial_mode = "normal",
            -- layout_config = { height = 40 },
          })
        end,
        desc = "Open File Browser in current buffer",
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local fb_actions = require("telescope").extensions.file_browser.actions

      opts = opts or {}
      opts.defaults = opts.defaults or {}

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
        file_ignore_patterns = {
          "node_modules/",
          ".git/"
        },
        wrap_results = true,
        layout_strategy = "horizontal",
        path_display = {
          "filename_first",
        },
        layout_config = {
          prompt_position = "top",
          preview_width = 0.45,
          width = 0.90,
          height = 0.90
        },
        sorting_strategy = "ascending",
        mappings = {
          n = {},
        },
      })

      opts.pickers = {
        diagnostics = {
          theme = "ivy",
          initial_mode = "normal",
          layout_config = {
            preview_cutoff = 9999,
          },
        },
      }
      opts.extensions = {
        file_browser = {
          -- disables netrw and use telescope-file-browser in its place
          hijack_netrw = true,
          mappings = {
            ["n"] = {
              ["q"] = actions.close,
              ["N"] = fb_actions.create,
              ["h"] = fb_actions.goto_parent_dir,
              ["/"] = function()
                vim.cmd("startinsert")
              end,
              ["<C-u>"] = function(prompt_bufnr)
                for _ = 1, 10 do
                  actions.move_selection_previous(prompt_bufnr)
                end
              end,
              ["<C-d>"] = function(prompt_bufnr)
                for _ = 1, 10 do
                  actions.move_selection_next(prompt_bufnr)
                end
              end,
              ["<PageUp>"] = actions.preview_scrolling_up,
              ["<PageDown>"] = actions.preview_scrolling_down,
              ["<C-k>"] = actions.preview_scrolling_up,
              ["<C-j>"] = actions.preview_scrolling_down,
              ["<C-h>"] = actions.preview_scrolling_left,
              ["<C-l>"] = actions.preview_scrolling_right,
            },
          },
        },
      }

      telescope.setup(opts)
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("file_browser")
    end,
  },
}
