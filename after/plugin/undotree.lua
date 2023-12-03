local enable = false

if not enable or not vim.cmd.UndotreeToggle then
  require('user.utils').info("skipped undotree")
  return
end

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Edit history" })
