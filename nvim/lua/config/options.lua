local g = vim.g     -- Global variables
local o = vim.o     -- Set options
local opt = vim.opt -- Set options (lua list/map-like)
local cmd = vim.cmd

-----------------------------------------------------------
-- General
-----------------------------------------------------------
o.mouse = 'a'                               -- Enable mouse support
o.clipboard = 'unnamedplus'                 -- Copy/paste to system clipboard
o.cursorline = true                         -- Highlight current line
o.cursorlineopt = "number"                  -- Highlight current line number
o.swapfile = false                          -- Don't use swapfile
o.completeopt = 'menuone,noinsert,noselect' -- Autocomplete options
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.undofile = true                             -- Save undo history to a file
opt.undodir = vim.fn.stdpath("data") .. "/undo" -- Local to save undo file
o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-----------------------------------------------------------
-- Neovim UI
-----------------------------------------------------------
o.relativenumber = true -- Show relative line number
o.number = true         -- Show line number
o.foldmethod = 'marker' -- Enable folding (default 'foldmarker')
o.splitright = true     -- Vertical split to the right
o.splitbelow = true     -- Horizontal split to the bottom
o.ignorecase = true     -- Ignore case letters when search
o.smartcase = true      -- Ignore lowercase for the whole pattern
o.linebreak = false     -- Wrap on word boundary
o.wrap = false          -- Disabled Wrap
o.termguicolors = true  -- Enable 24-bit RGB colors
o.laststatus = 3        -- Set global statusline
opt.scrolloff = 10      -- At least 10 lines above and below cursor

-- Undercurl
cmd([[let &t_Cs = "\e[4:3m"]])
cmd([[let &t_Ce = "\e[4:0m"]])

vim.diagnostic.config({ virtual_text = true }) -- Show inline diagnostics

-----------------------------------------------------------
-- Tabs, indent
-----------------------------------------------------------
o.expandtab = true   -- Use spaces instead of tabs
o.shiftwidth = 2     -- Shift 2 spaces when tab
o.tabstop = 2        -- 1 tab == 2 spaces
o.smartindent = true -- Autoindent new lines

-----------------------------------------------------------
-- Memory, CPU
-----------------------------------------------------------
o.hidden = true     -- Enable background buffers
o.history = 100     -- Remember N lines in history
o.lazyredraw = true -- Faster scrolling
o.synmaxcol = 240   -- Max column for syntax highlight
o.updatetime = 250  -- ms to wait for trigger an event

-----------------------------------------------------------
-- Global
-----------------------------------------------------------
g.mapleader = " "


-----------------------------------------------------------
-- Startup
-----------------------------------------------------------
-- Disable builtin plugins
local disabled_built_ins = {
  "2html_plugin",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "matchit",
  "tar",
  "tarPlugin",
  "rrhelper",
  "spellfile_plugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
  "tutor",
  "rplugin",
  "synmenu",
  "optwin",
  "compiler",
  "bugreport",
  "ftplugin",
}

for _, plugin in pairs(disabled_built_ins) do
  g["loaded_" .. plugin] = 1
end
