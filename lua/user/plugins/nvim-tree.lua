local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  require('user.utils').info("skipped nvim-tree")
  return
end

local PlenaryPath = require("plenary.path")

-- Forward refs so the setup() on_attach can call into routines defined below.
local TelescopeRoutines = {}
local telescope_ok, telescope = pcall(require, "telescope.builtin")
local preview_ok, preview = pcall(require, "nvim-tree-preview")
if preview_ok then
  preview.setup({
    min_width = 30,
    min_height = 10,
    max_width  = 120,
    max_height = 40,
    border = "rounded",
    show_title = true,
    title_pos  = "top-left",
    title_format = " %s ",
    follow_links = true,
    keymaps = {
      ["q"] = { action = "close", unwatch = true },
    },
  })
end

-- Persists watch on/off across tree close→reopen. Lua module-local, so it
-- survives any number of on_attach invocations until Neovim restarts.
local preview_enabled = false

-- ============================================================
-- 1. Run nvim-tree.setup FIRST so the API gets hydrated. All
--    subsequent code can safely call nvim_tree.api.* functions.
-- ============================================================
nvim_tree.setup({
  select_prompts = true, -- confirmations (remove/trash/overwrite) via vim.ui.select → snacks picker
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
    highlight_opened_files = "all",
    icons = {
      git_placement = "right_align",
    },
  },
  diagnostics = {
    enable = true,
    icons = { hint = "", info = "", warning = "", error = "" },
  },
  update_focused_file = {
    enable = true,
    update_cwd = false,
    ignore_list = {},
  },
  git = { enable = true, ignore = false, timeout = 500 },
  view = {
    width = 30,
    side = "left",
    number = false,
    relativenumber = false,
    float = {
      quit_on_focus_loss = true,
      open_win_config = { relative = "editor" },
    },
  },
  actions = {
    open_file = {
      quit_on_open = false,
      window_picker = {
        enable = true,
        picker = function() return require("window-picker").pick_window() end,
      },
    },
  },
  on_attach = function(bufnr)
    require("nvim-tree.api").config.mappings.default_on_attach(bufnr)
    local function opts(desc) return { desc = desc, buffer = bufnr, nowait = true } end
    if preview_ok then
      -- gp, not P: P stays nvim-tree's default "go to parent directory".
      vim.keymap.set('n', "gp", function()
        preview_enabled = not preview_enabled
        if preview_enabled then preview.watch() else preview.unwatch() end
      end, opts("Preview (toggle watch)"))
      vim.keymap.set('n', "<Tab>", function() return preview.node_under_cursor({ toggle_focus = true }) end, opts("Preview node"))
      vim.keymap.set('n', "<C-d>", function() return preview.scroll(4) end,   opts("Preview scroll down"))
      vim.keymap.set('n', "<C-u>", function() return preview.scroll(-4) end,  opts("Preview scroll up"))
      -- Restore previous watch state on every tree attach.
      if preview_enabled then
        vim.schedule(function() preview.watch() end)
      end
    end
    vim.keymap.set('n', "<Esc>", function()
      -- Close the float window, but don't flip `preview_enabled` —
      -- next tree open should restore whatever the user had toggled.
      if preview_ok then preview.unwatch() end
      require("nvim-tree.api").tree.close()
    end, opts("Close explorer"))

    -- o / <CR>: smart open.
    --   * 0 editor windows  -> open in a vertical split to the right
    --   * 1 editor window   -> open there directly (skip the window picker)
    --   * >=2 editor windows -> use the window picker as usual
    -- Avoids "pick a window" prompts when there's nothing to choose, and the
    -- "No windows left to pick after filtering" error when the tree is alone.
    local function open_file_smart()
      local api = require("nvim-tree.api")
      local node = api.tree.get_node_under_cursor()
      if not node then return end
      if node.type ~= "file" then
        api.node.open.edit(node) -- directories / links / '..': default behaviour
        return
      end

      -- Count real (non-floating, non-tree) editor windows.
      local editable = 0
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype ~= "NvimTree" then
            editable = editable + 1
          end
        end
      end

      -- Run `fn` with nvim-tree's window picker switched off. Needed whenever there
      -- is nothing to pick: with 0 or 1 editable windows the picker either prompts
      -- pointlessly or gets handed an empty candidate list, and then
      -- nvim-window-picker's floating-big-letter hint dies on self.chars[index]
      -- being nil (hints/floating-big-letter-hint.lua:129) — which surfaced as an
      -- E5108 traceback blaming this file instead of the picker.
      local function without_picker(fn)
        local cfg = require("nvim-tree.config")
        local wp = cfg.g and cfg.g.actions and cfg.g.actions.open_file and cfg.g.actions.open_file.window_picker
        local prev = wp and wp.enable
        if wp then wp.enable = false end
        local ok, err = pcall(fn)
        if wp then wp.enable = prev end
        return ok, err
      end

      local ok, err
      if editable == 0 then
        -- Nothing open yet: split off the tree rather than take over its window.
        local prev = vim.o.splitright
        vim.o.splitright = true
        ok, err = without_picker(function() api.node.open.vertical(node) end)
        vim.o.splitright = prev
      elseif editable == 1 then
        -- Open in the single existing window instead of prompting for it.
        ok, err = without_picker(function() api.node.open.edit(node) end)
      else
        ok, err = pcall(api.node.open.edit, node) -- >=2 windows: let the picker run
      end

      -- Re-raising with error() buried the real message under a Lua traceback about
      -- THIS file; a plugin's internal failure should just be reported.
      if not ok then
        vim.notify(
          "Could not open " .. node.name .. ": " .. tostring(err):match("[^\n]*"),
          vim.log.levels.ERROR,
          { title = "nvim-tree" }
        )
      end
    end
    vim.keymap.set('n', "o",    open_file_smart, opts("Open file (smart)"))
    vim.keymap.set('n', "<CR>", open_file_smart, opts("Open file (smart)"))

    -- Unified "open target" scheme (same keys as telescope / trouble):
    --   <CR>/o          open (smart) in the current/target window
    --   <M-h/j/k/l>     open in a split to the left / below / above / right
    --   <M-w>           pick a window (nvim-window-picker) and open there
    --   <C-t>           open in a new tab
    -- Directions flip 'splitright'/'splitbelow' around the open call, matching
    -- the `O` menu above. Bound explicitly even where nvim-tree's defaults would
    -- overlap (e.g. <C-t>), so the scheme is self-documenting.
    local api = require("nvim-tree.api")
    local function tree_open(open_fn, split_opt, value)
      return function()
        local node = api.tree.get_node_under_cursor()
        if not node or node.type ~= "file" then return end
        if preview_ok then preview.unwatch() end
        if split_opt then
          local prev = vim.o[split_opt]
          vim.o[split_opt] = value
          local ok, err = pcall(open_fn, node)
          vim.o[split_opt] = prev
          if not ok then error(err) end
        else
          open_fn(node)
        end
      end
    end
    vim.keymap.set('n', "<M-h>", tree_open(api.node.open.vertical,   "splitright", false), opts("Open: split left"))
    vim.keymap.set('n', "<M-j>", tree_open(api.node.open.horizontal, "splitbelow", true),  opts("Open: split below"))
    vim.keymap.set('n', "<M-k>", tree_open(api.node.open.horizontal, "splitbelow", false), opts("Open: split above"))
    vim.keymap.set('n', "<M-l>", tree_open(api.node.open.vertical,   "splitright", true),  opts("Open: split right"))
    vim.keymap.set('n', "<M-w>", tree_open(api.node.open.edit),  opts("Open: pick window")) -- window_picker enabled in config
    vim.keymap.set('n', "<C-t>", tree_open(api.node.open.tab),   opts("Open: new tab"))

    -- O: pick how to open — new tab / split in any direction.
    vim.keymap.set('n', "O", function()
      local api = require("nvim-tree.api")
      local node = api.tree.get_node_under_cursor()
      if not node or node.type ~= "file" then return end

      local function with_opt(name, value, fn)
        local prev = vim.o[name]
        vim.o[name] = value
        local ok, err = pcall(fn)
        vim.o[name] = prev
        if not ok then error(err) end
      end

      -- Pass `node` explicitly: by the time the menu callback fires, focus is
      -- in the picker's prompt buffer, so api.node.open.*() with no arg
      -- would re-query "node under cursor" and fail with E349.
      local choices = {
        { label = "  Tab",          fn = function() api.node.open.tab(node) end },
        { label = "  Split Right",  fn = function() with_opt("splitright", true,  function() api.node.open.vertical(node)   end) end },
        { label = "  Split Left",   fn = function() with_opt("splitright", false, function() api.node.open.vertical(node)   end) end },
        { label = "  Split Down",   fn = function() with_opt("splitbelow", true,  function() api.node.open.horizontal(node) end) end },
        { label = "  Split Up",     fn = function() with_opt("splitbelow", false, function() api.node.open.horizontal(node) end) end },
      }
      if preview_ok then preview.unwatch() end
      vim.ui.select(choices, {
        prompt = "Open " .. node.name,
        format_item = function(item) return item.label end,
      }, function(choice)
        if choice then choice.fn() end
      end)
    end, opts("Open with menu"))
    -- Expanding/collapsing the tree is folding, so use the fold keys instead of
    -- inventing tree-only ones (same vocabulary as the fold group in
    -- user/plugins/which-key.lua): capital = all levels, R/M = whole buffer,
    -- O/C = recursively under the cursor.
    --   zR / zM   whole tree, from the root
    --   zO / zC   the node under the cursor and everything below it
    -- nvim-tree's own E (expand node) and W (collapse tree) keep working.
    --
    -- zR cannot go through api.tree.expand_all(): that wrapper replaces a nil node
    -- argument with the node under the cursor (nvim-tree/api/impl.lua), which is
    -- exactly why E only ever expands a subtree. Explorer:expand_all(nil) is the
    -- "no node -> start at the root" path, so it doesn't care where the cursor is
    -- or whether the root row is rendered at all.
    vim.keymap.set('n', "zR", function()
      local explorer = require("nvim-tree.core").get_explorer()
      if explorer then explorer:expand_all(nil) end
    end, opts("Expand all (whole tree)"))
    vim.keymap.set('n', "zM", function() api.tree.collapse_all() end, opts("Collapse all (whole tree)"))

    -- zo / zc / za: one level, the directory under the cursor only. Without these
    -- the tree buffer falls through to the real fold commands (nvim-tree maps no z
    -- keys, and keymap.lua's global zo -> za is still in effect here), which can
    -- only fail with E490 since the tree has foldmethod=manual and no folds.
    --
    -- zo is a TOGGLE, deliberately: keymap.lua:62 remaps zo -> za globally, so in
    -- text zo already toggles. Keeping the tree's zo a strict "open" would make the
    -- same key mean two different things depending on the buffer. zo and za are
    -- therefore the same action here — api.node.open.edit() is itself a directory
    -- toggle.
    local function toggle_dir_one_level()
      local node = api.tree.get_node_under_cursor()
      if node and node.type == "directory" then api.node.open.edit(node) end
    end

    vim.keymap.set('n', "zo", toggle_dir_one_level, opts("Toggle node (one level)"))
    -- zc stays a plain close: it checks node.open first, otherwise it would re-open
    -- what it just closed. On a file it closes the containing directory, like a real
    -- fold does.
    vim.keymap.set('n', "zc", function()
      local node = api.tree.get_node_under_cursor()
      if node and node.type == "directory" and node.open then
        api.node.open.edit(node)
      else
        api.node.navigate.parent_close(node)
      end
    end, opts("Collapse node (one level)"))

    -- za / zA: toggle, one level / recursively. za shares zo's callback (see above);
    -- zA picks expand-or-collapse from the node's current state. (zt/zz/zb stay the
    -- plain scroll commands here — the tree is an ordinary window.)
    vim.keymap.set('n', "za", toggle_dir_one_level, opts("Toggle node (one level)"))
    vim.keymap.set('n', "zA", function()
      local node = api.tree.get_node_under_cursor()
      if not node or node.type ~= "directory" then return end
      if node.open then api.node.collapse(node) else api.tree.expand_all(node) end
    end, opts("Toggle node recursively"))
    vim.keymap.set('n', "zO", function() api.tree.expand_all() end,   opts("Expand node recursively"))
    vim.keymap.set('n', "zC", function() api.node.collapse() end,     opts("Collapse node"))


    -- <leader>y…: the same yank-path trio as init/keymap.lua:23-25, retargeted at
    -- the node under the cursor. The globals go through expand("%"), and in the
    -- tree that is the tree's own buffer ("NvimTree_1"), so they would silently
    -- yank something that is not a file at all. nvim-tree's API does the copying,
    -- so these behave exactly like its native y / Y / gy (system clipboard plus
    -- the "copied to clipboard" message), and directories work as-is.
    vim.keymap.set('n', "<leader>yn", api.fs.copy.filename,      opts("󰷊 Copy file name"))
    vim.keymap.set('n', "<leader>yr", api.fs.copy.relative_path, opts("󰷊 Copy relative path"))
    vim.keymap.set('n', "<leader>ya", api.fs.copy.absolute_path, opts("󰷊 Copy absolute path"))

    -- Bookmarks (toggled with nvim-tree's default `m`): ]m / [m jump between them
    -- like treesitter's ]m / [m jump between functions in code buffers;
    -- <leader>m picks one from a list (vim.ui.select).
    vim.keymap.set('n', "]m", api.marks.navigate.next,   opts("Next bookmark"))
    vim.keymap.set('n', "[m", api.marks.navigate.prev,   opts("Prev bookmark"))
    vim.keymap.set('n', "<leader>m", api.marks.navigate.select, opts("Select bookmark"))

    if telescope_ok then
      vim.keymap.set('n', "<leader>fG", TelescopeRoutines.launch_live_grep, { desc = "Grep in Selected node", buffer = bufnr })
      vim.keymap.set('n', "<leader>fF", TelescopeRoutines.launch_find_files, { desc = "Find files in selected node", buffer = bufnr })
    end
  end,
})

-- ============================================================
-- 2. Now the API is hydrated — safe to capture refs.
-- ============================================================
-- Back-compat shim: current nvim-tree no longer exposes `.config` on the
-- main module, but b0o/nvim-tree-preview reads `require("nvim-tree").config.view.side`.
-- Without this, watch() crashes with: attempt to index field 'config' (a nil value).
nvim_tree.config = nvim_tree.config or { view = { side = "left" } }

local nvim_tree_api  = require("nvim-tree.api")
local nvim_tree_core = require("nvim-tree.core")
local nvim_tree_view = require("nvim-tree.view")

-- ============================================================
-- 3. Telescope routines (use real API funcs now).
-- ============================================================
if telescope_ok then
  local telescope_actions = require("telescope.actions")
  local telescope_action_state = require("telescope.actions.state")
  local nvim_tree_openfile = require("nvim-tree.actions.node.open-file")

  local view_selection = function(prompt_bufnr, _)
    telescope_actions.select_default:replace(function()
      telescope_actions.close(prompt_bufnr)
      local selection = telescope_action_state.get_selected_entry()
      local filename = selection.filename
      if filename == nil then filename = selection[1] end
      -- 'edit' opens the file and moves focus to it; 'preview' would keep the
      -- cursor in the nvim-tree window.
      nvim_tree_openfile.fn('edit', filename)
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
    local node = nvim_tree_api.tree.get_node_under_cursor()
    local is_folder = node.fs_stat and node.fs_stat.type == "directory" or false
    local basedir = is_folder and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ":h")
    local tree_cwd = nvim_tree_core.get_cwd()
    if node.name == ".." and tree_cwd ~= nil then basedir = tree_cwd end

    local basedir_relative_path = PlenaryPath:new(basedir):make_relative(vim.fn.getcwd() .. "/")
    local basedir_repr = string.sub(basedir_relative_path, -25)
    if basedir_relative_path ~= basedir_repr then basedir_repr = "..." .. basedir_relative_path end
    opts = opts or {}
    opts.cwd = basedir
    opts.search_dirs = { basedir }
    opts.prompt_title = func_name .. " in " .. basedir_repr
    opts.attach_mappings = view_selection
    return telescope[func_name](opts)
  end

  local function open_nvim_tree(prompt_bufnr, _)
    telescope_actions.select_default:replace(function()
      telescope_actions.close(prompt_bufnr)
      local selection = telescope_action_state.get_selected_entry()
      nvim_tree_api.tree.open()
      nvim_tree_api.tree.find_file(selection.cwd .. "/" .. selection.value)
    end)
    return true
  end

  function TelescopeRoutines.find_directory_and_focus()
    telescope.find_files({
      find_command = { "fd", "--type", "directory", "--hidden", "--exclude", ".git/*" },
      attach_mappings = open_nvim_tree,
    })
  end

  vim.keymap.set('n', "<leader>fD", TelescopeRoutines.find_directory_and_focus, { desc = "Find directory and NvimTree Focus" })
end

-- ============================================================
-- 4. Toggle between sidebar/float modes — wiki recipe.
-- ============================================================
local current_float_mode = false
local function nvimTreeFocusOrToggle(float)
  if float == nil then float = false end

  local cfg = require("nvim-tree.config")
  if cfg.g and cfg.g.view and cfg.g.view.float then
    cfg.g.view.float.enable = float
  end
  -- Auto-close the tree after opening a file when in float mode — keep
  -- sidebar mode persistent (the user's existing behaviour).
  if cfg.g and cfg.g.actions and cfg.g.actions.open_file then
    cfg.g.actions.open_file.quit_on_open = float
  end

  if nvim_tree_view.is_visible() and current_float_mode ~= float then
    nvim_tree_api.tree.close()
  end
  current_float_mode = float

  local currentBufFt = vim.api.nvim_get_option_value("filetype", { buf = 0 })
  if currentBufFt == "NvimTree" then
    nvim_tree_api.tree.toggle({ find_file = true, focus = true, update_root = true })
  else
    nvim_tree_api.tree.focus()
  end
end

vim.keymap.set('n', "<leader>e", function() nvimTreeFocusOrToggle(false) end, { desc = "󰙅 Explorer (sidebar)" })
vim.keymap.set('n', "<leader>E", function() nvimTreeFocusOrToggle(true) end,  { desc = "󰙅 Explorer (float)" })
