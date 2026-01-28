return {
	{
		"datsfilipe/min-theme.nvim",
		priority = 1000,
		opts = {
			transparent = true,
		},
		config = function(_, opts)
			require("min-theme").setup(opts)

			vim.cmd("colorscheme min-theme")
		end,
	},
}
