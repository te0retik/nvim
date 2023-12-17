local ok, todo = pcall(require, "todo-comments")
if not ok then
  require('user.utils').info('skipped todo-comments')
  return
end

todo.setup({
  signs = false,
  -- sign_priority = 999,
  highlight = {
     -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters)
    keyword = "bg",
    pattern = "\\W(KEYWORDS)[:?( ].*",
    comments_only = true,
    multiline = false,
  },
  merge_keywords = false,
  keywords = {
    fix = {
      icon = " ",
      color = "error",
      alt = { "FIXME", "fixme", "BUG", "bug", "FIXIT", "fixit", "ISSUE", "issue" },
    },
    todo = {
      icon = " ",
      color = "hint",
      alt = { "TODO", "todo" }
    },
    hack = {
      icon = " ",
      color = "warning"
    },
    warn = {
      icon = " ",
      color = "warning",
      alt = { "WARNING", "XXX", "warn" }
    },
    perf = {
      icon = " ",
      alt = { "OPTIM", "optim", "PERFORMANCE", "performance", "OPTIMIZE", "optimize" }
    },
    note = {
      icon = ' ',
      color = "hint",
      alt = nil
      --{
      -- "INFO", "info"
      -- }
    },
    -- test = { icon = "⏲ ", color = "test", alt = { "TESTING", "testing", "PASSED", "passed", "FAILED", "failed" } },
  },
  search = {
    command = "rg",
    args = {
      "--no-heading",
      "--line-number",
      "--column",
      "--with-filename",
      -- "--color=never",
      "--smart-case",
      "--hidden",
      "--trim",
      "--glob=!vendor",
      "--glob=!node_modules",
      "--glob=!.git",
      "--glob=!.py",
      "--glob=!.csv",
      "--glob=!.json",
    },
    pattern = "[^\\w](KEYWORDS)[:?( ]",
  },
})

vim.api.nvim_set_keymap("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc=" TODOs", noremap = true, silent = true })
