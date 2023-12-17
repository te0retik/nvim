local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  require('user.utils').info("skipped nvim-tree")
  return
end

local PlenaryPath = require("plenary.path")
local float_preview_ok, float_preview = pcall(require, "float-preview")

local nvim_tree_api = require("nvim-tree.api")
local nvim_tree_core = require("nvim-tree.core")
local nvim_tree_view = require("nvim-tree.view")

local nnoremap = require("user.utils").nnoremap

local TelescopeRoutines = {}
local telescope_ok, telescope = pcall(require, "telescope.builtin")
if telescope_ok then
  local telescope_actions = require("telescope.actions")
  local telescope_action_state = require("telescope.actions.state")
  local nvim_tree_openfile = require("nvim-tree.actions.node.open-file")

  local view_selection = function(prompt_bufnr, map)
    telescope_actions.select_default:replace(function()
      telescope_actions.close(prompt_bufnr)
      local selection = telescope_action_state.get_selected_entry()
      local filename = selection.filename
      if (filename == nil) then
        filename = selection[1]
      end
      nvim_tree_openfile.fn('preview', filename)
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
    if not telescope_ok then return end
    local node = nvim_tree_api.tree.get_node_under_cursor()
    local is_folder = node.fs_stat and node.fs_stat.type == "directory" or false
    local basedir = is_folder and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ":h")
    local tree_cwd = nvim_tree_core.get_cwd()
    if (node.name == ".." and tree_cwd ~= nil) then
      basedir = tree_cwd
    end

    local basedir_relative_path = PlenaryPath:new(basedir):make_relative(vim.fn.getcwd() .. "/")
    local basedir_repr = string.sub(basedir_relative_path, -25) -- show last N symbols
    if basedir_relative_path ~= basedir_repr then
      basedir_repr = "..." .. basedir_relative_path
    end
    opts = opts or {}
    opts.cwd = basedir
    opts.search_dirs = { basedir }
    opts.prompt_title = func_name .. " in " .. basedir_repr
    opts.attach_mappings = view_selection

    return telescope[func_name](opts)
  end

  function TelescopeRoutines._open_nvim_tree(prompt_bufnr, _)
    telescope_actions.select_default:replace(function()
      telescope_actions.close(prompt_bufnr)
      local selection = telescope_action_state.get_selected_entry()
      nvim_tree_api.tree.open()
      nvim_tree_api.tree.find_file(selection.cwd .. "/" .. selection.value)
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

  nnoremap("<leader>fD", TelescopeRoutines.find_directory_and_focus, "Find directory and NvimTree Focus")
end

local function nvimTreeFocusOrToggle(float) -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes
  local float_enabled = nvim_tree.config.view.float.enable
  if float == nil then
    float = false
  end
  nvim_tree.config.view.float.enable = float

  if nvim_tree_view.is_visible() and float_enabled ~= float then -- close tree to open after in `float` mode
    nvim_tree_api.tree.close()
  end

  local currentBuf = vim.api.nvim_get_current_buf()
  local currentBufFt = vim.api.nvim_get_option_value("filetype", { buf = currentBuf })
  local tree_is_active = currentBufFt == "NvimTree"

  if tree_is_active then
    nvim_tree_api.tree.toggle({ find_file = true, focus = true, update_root = true })
  else
    nvim_tree_api.tree.focus()
  end
end

nnoremap("<leader>E", function() nvimTreeFocusOrToggle(true) end, "󰙅 Explorer float")
nnoremap("<leader>e", function() nvimTreeFocusOrToggle(false) end, "󰙅 Explorer show Current file")

if float_preview_ok then
  float_preview.setup({
    mapping = {
      up = { "<C-e>", "<C-u>" },
      down = { "<C-d>" },
      toggle = { "<Tab>", "p" },
    },
  })
  float_preview.toggle() -- set ide on startup
end

nvim_tree.setup({
  respect_buf_cwd = true,
  sync_root_with_cwd = true,
  disable_netrw = true,
  hijack_netrw = false,
  open_on_tab = false,
  hijack_cursor = false,
  update_cwd = false,
  renderer = {
    full_name = true,
    highlight_git = true,
    root_folder_modifier = ":~",
    highlight_opened_files = "all", -- can be `"none"`, `"icon"`, `"name"` or `"all"`
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
    ignore = false,
    timeout = 500,
  },
  view = {
    width = 30,
    side = "left",
    number = false,
    relativenumber = false,
    float = {
      quit_on_focus_loss = true,
      open_win_config = {
        relative = "editor",
        -- relative = "cursor",
      }
    }
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
    nvim_tree_api.config.mappings.default_on_attach(bufnr)
    if telescope_ok then
      nnoremap("<leader>fG", TelescopeRoutines.launch_live_grep, "Grep in Selected node", { buffer = bufnr })
      nnoremap("<leader>fF", TelescopeRoutines.launch_find_files, "Find files in selected node", { buffer = bufnr })
    end

    if float_preview_ok then
      float_preview.attach_nvimtree(bufnr)
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

-- vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer", noremap = true, remap = false })
