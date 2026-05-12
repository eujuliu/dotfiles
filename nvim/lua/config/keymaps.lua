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

-- Window Maximize
keymap.set("n", "<C-w>z", function()
  vim.cmd("wincmd |")
  vim.cmd("wincmd _")
end, {
  desc = "Window Maximize",
})

-- Save with Ctrl + S
keymap.set({ "n", "i", "v", "s" }, "<C-s>", function()
  vim.cmd("stopinsert")

  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({
      async = false,
      lsp_fallback = true,
    })
  end

  vim.cmd("update")
end, { desc = "Format with Conform, save, and go to normal mode" })

-- Clear search highlight
keymap.set("n", "<Esc>", function()
  if vim.v.hlsearch == 1 then
    vim.cmd("nohlsearch")
  end
end, { desc = "Clear search highlight" })
