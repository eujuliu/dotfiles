local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- New tab
keymap.set("n", "te", ":tabedit")
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)

-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

-- Move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- Save with Ctrl + S
keymap.set({ "n", "i", "v", "s" }, "<C-s>", function()
  -- Always go back to normal mode
  vim.cmd("stopinsert")

  -- Run Conform formatter (safe call)
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({
      async = false,       -- wait for formatting before saving
      lsp_fallback = true, -- fallback to LSP if no formatter
    })
  end

  -- Save only if buffer changed
  vim.cmd("update")
end, { desc = "Format with Conform, save, and go to normal mode" })
