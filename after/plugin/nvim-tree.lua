local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  require('user.utils').info("skipped nvim-tree")
  return
end

local nnoremap = require("user.utils").nnoremap

local TelescopeRoutines = {}
local tree_api = require("nvim-tree.api")
local telescope_ok, telescope = pcall(require, "telescope.builtin")
if telescope_ok then
  local telescope_actions = require("telescope.actions")
  local telescope_action_state = require("telescope.actions.state")
  local tree_openfile = require("nvim-tree.actions.node.open-file")

  local view_selection = function(prompt_bufnr, map)
    telescope_actions.select_default:replace(function()
      telescope_actions.close(prompt_bufnr)
      local selection = telescope_action_state.get_selected_entry()
      local filename = selection.filename
      if (filename == nil) then
        filename = selection[1]
      end
      tree_openfile.fn('preview', filename)
    end)

    return true
  end

  function TelescopeRoutines.launch_live_grep(opts)
    return TelescopeRoutines._launch_telescope("live_grep", opts)
  end

  function TelescopeRoutines.launch_find_files(opts)
    return TelescopeRoutines._launch_telescope("find_files", opts)
  end

  function TelescopeRoutines._launch_telescope(func_name, opts)
    local telescope_status_ok, _ = pcall(require, "telescope")
    if not telescope_status_ok then
      return
    end
    local node = tree_api.tree.get_node_under_cursor()
    local is_folder = node.fs_stat and node.fs_stat.type == 'directory' or false
    local basedir = is_folder and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ":h")
    if (node.name == '..' and TreeExplorer ~= nil) then
      basedir = TreeExplorer.cwd
    end
    opts = opts or {}
    opts.cwd = basedir
    opts.search_dirs = { basedir }
    opts.attach_mappings = view_selection

    return telescope[func_name](opts)
  end

  function TelescopeRoutines._open_nvim_tree(prompt_bufnr, _)
    telescope_actions.select_default:replace(function()
      telescope_actions.close(prompt_bufnr)
      local selection = telescope_action_state.get_selected_entry()
      tree_api.tree.open()
      tree_api.tree.find_file(selection.cwd .. "/" .. selection.value)
    end)
    return true
  end

  function TelescopeRoutines.find_directory_and_focus()
    -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes#find-and-focus-directory-with-telescope
    telescope.find_files({
      find_command = { "fd", "--type", "directory", "--hidden", "--exclude", ".git/*" },
      attach_mappings = TelescopeRoutines._open_nvim_tree,
    })
  end
end

local nvimTreeFocusOrToggle = function() -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes
  local currentBuf = vim.api.nvim_get_current_buf()
  local currentBufFt = vim.api.nvim_get_option_value("filetype", { buf = currentBuf })
  if currentBufFt == "NvimTree" then
    tree_api.tree.toggle({ find_file = true, focus = true, update_root = false })
  else
    tree_api.tree.focus()
  end
end

nnoremap("<leader>E", "<cmd>NvimTreeToggle<CR>", "Explorer")
nnoremap("<leader>e", nvimTreeFocusOrToggle, "Explorer show Current file")

nvim_tree.setup({
  disable_netrw = true,
  hijack_netrw = false,
  open_on_tab = false,
  hijack_cursor = false,
  update_cwd = false,
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
    update_cwd = false,
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
  on_attach = function(bufnr)
    tree_api.config.mappings.default_on_attach(bufnr)
    if telescope_ok then
      nnoremap("<leader>fg", TelescopeRoutines.launch_live_grep, "grep in selected node", { buffer = bufnr })
      nnoremap("<leader>ff", TelescopeRoutines.launch_find_files, "Find files in selected node", { buffer = bufnr })
    end
  end
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

nnoremap("<leader>fF", TelescopeRoutines.find_directory_and_focus, "Find directory and NvimTree Focus")
-- vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer", noremap = true, remap = false })
