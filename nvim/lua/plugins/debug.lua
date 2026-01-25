return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local mason_dap = require("mason-nvim-dap")
      local dap = require("dap")
      -- local ui = require("dapui")
      local dap_virtual_text = require("nvim-dap-virtual-text")

      -- Dap Virtual Text
      dap_virtual_text.setup({})

      mason_dap.setup({
        ensure_installed = { "node2", "php", "javadbg" },
        automatic_installation = true,
        handlers = {
          function(config)
            require("mason-nvim-dap").default_setup(config)
          end,
        },
      })

      -- Configurations
      dap.configurations = {
        javascript = {
          {
            name = "Launch",
            type = "node2",
            request = "launch",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
          },
          {
            -- For this to work you need to make sure the node process is started with the `--inspect` flag.
            name = "Attach to process",
            type = "node2",
            request = "attach",
            processId = require("dap.utils").pick_process,
          },
        },
        php = {
          {
            type = "php",
            request = "launch",
            name = "Listen for Xdebug",
            port = 9003,
          },
        },
        java = {
          {
            type = "java",
            request = "attach",
            name = "Debug (Attach) - Remote",
            hostName = "127.0.0.1",
            port = 5005,
          },
        },
      }
    end,
    keys = {
      -- Debugger
      {
        "<leader>d",
        group = "Debugger",
        nowait = true,
        remap = false,
      },
      {
        "<leader>dt",
        function()
  require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
        nowait = true,
        remap = false,
      },
      {
        "<leader>dc",
        function()
  require("dap").continue()
        end,
        desc = "Continue",
        nowait = true,
        remap = false,
      },
      {
        "<leader>di",
        function()
  require("dap").step_into()
        end,
        desc = "Step Into",
        nowait = true,
        remap = false,
      },
      {
        "<leader>do",
        function()
  require("dap").step_over()
        end,
        desc = "Step Over",
        nowait = true,
        remap = false,
      },
      {
        "<leader>du",
        function()
  require("dap").step_out()
        end,
        desc = "Step Out",
        nowait = true,
        remap = false,
      },
      {
        "<leader>dr",
        function()
  require("dap").repl.open()
        end,
        desc = "Open REPL",
        nowait = true,
        remap = false,
      },
      {
        "<leader>dl",
        function()
  require("dap").run_last()
        end,
        desc = "Run Last",
        nowait = true,
        remap = false,
      },
      {
        "<leader>dq",
        function()
  require("dap").terminate()
  require("dapui").close()
  require("nvim-dap-virtual-text").toggle()
        end,
        desc = "Terminate",
        nowait = true,
        remap = false,
      },
      {
        "<leader>db",
        function()
  require("dap").list_breakpoints()
        end,
        desc = "List Breakpoints",
        nowait = true,
        remap = false,
      },
      {
        "<leader>de",
        function()
  require("dap").set_exception_breakpoints({ "all" })
        end,
        desc = "Set Exception Breakpoints",
        nowait = true,
        remap = false,
      },
    },
  },
}
