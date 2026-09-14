local ok, kulala = pcall(require, "kulala")
if not ok then
  require("user.utils").info("skipped kulala")
  return
end

kulala.setup({})

-- Deliberately NOT <leader>tt / <leader>tT: those are the terminal toggles in
-- user/plugins/snacks.lua, and a buffer-local mapping always wins over a global
-- one, so inside an .http file the bottom-split and new-tab terminals would be
-- unreachable. tr/tR (run, replay) and tE/te (select env, show env) are free.
local function setup_keymaps()
  vim.keymap.set("n", "<leader>tr", function() kulala.run() end,    { buffer = 0, desc = "󰖟 Execute request" })
  vim.keymap.set("n", "<leader>tR", function() kulala.replay() end, { buffer = 0, desc = "kulala: replay last request" })
  vim.keymap.set("n", "<leader>tE", "<cmd>Kulala env select<cr>",   { buffer = 0, desc = "kulala: select env" })
  vim.keymap.set("n", "<leader>te", "<cmd>Kulala env current<cr>",  { buffer = 0, desc = "kulala: show current env" })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "http", "rest" },
  group = vim.api.nvim_create_augroup("UserKulala", { clear = true }),
  callback = setup_keymaps,
})
