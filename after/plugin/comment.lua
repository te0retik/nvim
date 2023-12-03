local ok, comment = pcall(require, "Comment")
if not ok then
  require('user.utils').info("skipped comment")
  return
end

comment.setup({
  mappings = {
    basic = false,
    extra = false,
  },
  -- https://github.com/numToStr/Comment.nvim/blob/master/lua/Comment/init.lua
  toggler = nil,  -- used if mappings.basic
  opleader = nil, -- used if mappings.basic
})

vim.keymap.set("n", "<leader>c", "<Plug>(comment_toggle_linewise_current)", { desc = "Toggle comment" })
vim.keymap.set("v", "<leader>c", "<Plug>(comment_toggle_linewise_visual)", { desc = "Toggle comment" })
