local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  require('user.utils').info("skipped nvim-tree")
  return
end

vim.keymap.set("n", "<leader>E", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer", noremap = true, remap = false })
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Explorer show Current file", noremap = true, remap = false })

nvim_tree.setup({
  disable_netrw = false,
  hijack_netrw = false,
  open_on_tab = false,
  hijack_cursor = false,
  update_cwd = true,
  renderer = {
    highlight_git = true,
    root_folder_modifier = ":~",
  },
  diagnostics = {
    enable = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  update_focused_file = {
    enable = true,
    update_cwd = true,
    ignore_list = {},
  },
  git = {
    enable = true,
    ignore = true,
    timeout = 500,
  },
  view = {
    width = 30,
    side = "left",
    number = false,
    relativenumber = false,
  },
  actions = {
    open_file = {
      quit_on_open = false,
      window_picker = {
        enable = true,
      },
    },
  },
  -- quit_on_open = 0,
  -- git_hl = 1,
  -- disable_window_picker = 0,
  -- root_folder_modifier = ":t",
  -- show_icons = {
  --   git = 1,
  --   folders = 1,
  --   files = 1,
  --   folder_arrows = 1,
  --   tree_width = 30,
  -- },
})

-- vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer", noremap = true, remap = false })
