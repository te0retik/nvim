local ok, diffview = pcall(require, "diffview")
if not ok then
  require('user.utils').info('skipped diffview')
  return
end

local cb = require("diffview.config").diffview_callback

diffview.setup({
  diff_binaries = false, -- Show diffs for binaries
  use_icons = false,
  file_panel = {
    win_config = {
      position = "left",               -- One of 'left', 'right', 'top', 'bottom'
      width = 35,                      -- Only applies when position is 'left' or 'right'
      height = 10,                     -- Only applies when position is 'top' or 'bottom'
    },
    listing_style = "tree",            -- One of 'list' or 'tree'
    tree_options = {                   -- Only applies when listing_style is 'tree'
      flatten_dirs = true,             -- Flatten dirs that only contain one single dir
      folder_statuses = "only_folded", -- One of 'never', 'only_folded' or 'always'.
    },
  },
  file_history_panel = {
    win_config = {
      position = "bottom",
      width = 35,
      height = 16,
    },
  },
  default_args = { -- Default args prepended to the arg-list for the listed commands
    DiffviewOpen = {},
    DiffviewFileHistory = {},
  },
  hooks = {},                 -- See ':h diffview-config-hooks'
  key_bindings = {
    disable_defaults = false, -- Disable the default key bindings
    -- The `view` bindings are active in the diff buffers, only when the current
    -- tabpage is a Diffview.
    view = {
      ["<tab>"]     = cb("select_next_entry"), -- Open the diff for the next file
      ["<s-tab>"]   = cb("select_prev_entry"), -- Open the diff for the previous file
      ["<leader>e"] = cb("focus_files"),       -- Bring focus to the files panel
      ["<leader>n"] = cb("toggle_files"),      -- Toggle the files panel.
      ["q"]         = cb("close"),
    },
    file_panel = {
      ["j"]             = cb("next_entry"),   -- Bring the cursor to the next file entry
      ["<down>"]        = cb("next_entry"),
      ["k"]             = cb("prev_entry"),   -- Bring the cursor to the previous file entry.
      ["<up>"]          = cb("prev_entry"),
      ["<cr>"]          = cb("select_entry"), -- Open the diff for the selected entry.
      ["o"]             = cb("select_entry"),
      ["<2-LeftMouse>"] = cb("select_entry"),
      ["-"]             = cb("toggle_stage_entry"), -- Stage / unstage the selected entry.
      ["S"]             = cb("stage_all"),          -- Stage all entries.
      ["U"]             = cb("unstage_all"),        -- Unstage all entries.
      ["X"]             = cb("restore_entry"),      -- Restore entry to the state on the left side.
      ["R"]             = cb("refresh_files"),      -- Update stats and entries in the file list.
      ["<tab>"]         = cb("select_next_entry"),
      ["<s-tab>"]       = cb("select_prev_entry"),
      ["<leader>e"]     = cb("focus_files"),
      ["<leader>n"]     = cb("toggle_files"),
    },
    file_history_panel = {
      ["g!"]            = cb("options"),          -- Open the option panel
      ["<C-A-d>"]       = cb("open_in_diffview"), -- Open the entry under the cursor in a diffview
      ["y"]             = cb("copy_hash"),        -- Copy the commit hash of the entry under the cursor
      ["zR"]            = cb("open_all_folds"),
      ["zM"]            = cb("close_all_folds"),
      ["j"]             = cb("next_entry"),
      ["<down>"]        = cb("next_entry"),
      ["k"]             = cb("prev_entry"),
      ["<up>"]          = cb("prev_entry"),
      ["<cr>"]          = cb("select_entry"),
      ["o"]             = cb("select_entry"),
      ["<2-LeftMouse>"] = cb("select_entry"),
      ["<tab>"]         = cb("select_next_entry"),
      ["<s-tab>"]       = cb("select_prev_entry"),
      ["gf"]            = cb("goto_file"),
      ["<C-w><C-f>"]    = cb("goto_file_split"),
      ["<C-w>gf"]       = cb("goto_file_tab"),
      ["<leader>e"]     = cb("focus_files"),
      ["<leader>b"]     = cb("toggle_files"),
    },
    option_panel = {
      ["<tab>"] = cb("select"),
      ["q"]     = cb("close"),
    },
  },
})


vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview" })
