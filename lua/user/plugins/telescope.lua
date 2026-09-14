local ok, telescope = pcall(require, "telescope")
if not ok then
  require('user.utils').info("skipped telescope")
  return
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Run a telescope select action, then explicitly place the cursor on the entry's
-- line/col. Telescope's default select jumps to the line for grep-style entries,
-- but when the target file is *already open* in a buffer it only switches to it
-- without moving the cursor. Setting the cursor ourselves covers that case too.
-- Entries without a line (e.g. find_files) carry no `lnum`, so we leave them alone.
local function select_and_line(prompt_bufnr, action)
  local entry = action_state.get_selected_entry()
  local query = action_state.get_current_line() -- grab the live prompt before the picker closes
  ;(action or actions.select_default)(prompt_bufnr)
  if entry and entry.lnum then
    -- Grep-style results carry a line number: echo the search string into the /
    -- register and enable hlsearch, so the matches light up in the opened file.
    -- Clear it afterwards with <leader>fC (:nohlsearch). The live_grep prompt is a
    -- ripgrep (Rust) regex; prefixing \v (very magic) makes Vim's regex dialect
    -- line up with it (| + ? ( ) { } are metacharacters in both), so plain text
    -- and most regexes highlight faithfully. Rare Vim-vs-Rust differences (e.g.
    -- \b word-boundary) can still mismatch.
    if query and query ~= "" then
      vim.fn.setreg("/", "\\v" .. query)
      vim.o.hlsearch = true
    end
    vim.schedule(function()
      if pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum, (entry.col or 1) - 1 }) then
        vim.cmd("normal! zz")
      end
    end)
  end
end

-- ── Unified "open target" scheme (shared across telescope / nvim-tree / trouble) ──
--   <CR>            open in the current window
--   <M-h/j/k/l>     open in a split to the left / below / above / right
--   <M-w>           pick a window with nvim-window-picker, open there
--   <C-t>           open in a new tab
local select_with_line = function(prompt_bufnr) select_and_line(prompt_bufnr) end
local select_tab       = function(prompt_bufnr) select_and_line(prompt_bufnr, actions.select_tab) end

-- Telescope only exposes horizontal/vertical; the actual side is governed by
-- 'splitright' / 'splitbelow', so we flip the relevant option around the action
-- (same trick as nvim-tree.lua's Split Right/Left/Up/Down) and restore it after.
local function open_split(action, opt, value)
  return function(prompt_bufnr)
    local prev = vim.o[opt]
    vim.o[opt] = value
    select_and_line(prompt_bufnr, action)
    vim.schedule(function() vim.o[opt] = prev end)  -- restore after the split opens
  end
end

local split_left  = open_split(actions.select_vertical,   "splitright", false)
local split_right = open_split(actions.select_vertical,   "splitright", true)
local split_up    = open_split(actions.select_horizontal, "splitbelow", false)
local split_down  = open_split(actions.select_horizontal, "splitbelow", true)

-- Close the picker, let the user choose a target window with nvim-window-picker,
-- then open the selected file there (honouring the entry's line/col).
local function open_in_picked_window(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  if not entry then return end
  local filename = entry.path or entry.filename or entry.value
  actions.close(prompt_bufnr)
  vim.schedule(function()
    -- window-picker may have nothing to offer: a single-window layout
    -- (include_current_win=false, navigation.lua) or only windows it filters out
    -- (nvim-tree, terminals, notifications…). It warns "No windows left to pick
    -- after filtering" and returns nil in that case — silence that warning and
    -- fall back to opening in the current window. (Replicating its filetype /
    -- buftype filters here would just drift out of sync.)
    local win
    local ok_wp, wp = pcall(require, "window-picker")
    if ok_wp then
      local orig = vim.notify
      vim.notify = function() end -- swallow the "no windows left" warning
      local ok, res = pcall(wp.pick_window)
      vim.notify = orig
      win = ok and res or nil
    end
    if win then vim.api.nvim_set_current_win(win) end
    vim.cmd("edit " .. vim.fn.fnameescape(filename))
    if entry.lnum and pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum, (entry.col or 1) - 1 }) then
      vim.cmd("normal! zz")
    end
  end)
end

telescope.setup({
  pickers = {
    find_files = {
      find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*", "--glob", "!**/.py/*" },
    },
    buffers = {
      sort_lastused = true,
      ignore_current_buffer = false,
    }
  },
  defaults = {
    mappings = {
      n = {
        ["dd"]    = "delete_buffer",
        ["<c-b>"] = "delete_buffer",
        -- unified open scheme (see helpers above)
        ["<cr>"]  = select_with_line,      -- open in current window
        ["<M-h>"] = split_left,            -- split → left
        ["<M-j>"] = split_down,            -- split → below
        ["<M-k>"] = split_up,              -- split → above
        ["<M-l>"] = split_right,           -- split → right
        ["<M-w>"] = open_in_picked_window, -- pick target window
        ["<c-t>"] = select_tab,            -- new tab
        -- half-screen scroll inside the results list (Ctrl+Shift)
        ["<C-S-u>"] = "results_scrolling_up",
        ["<C-S-d>"] = "results_scrolling_down",
        -- preview pane scrolling
        ["<c-f>"] = "preview_scrolling_down",
        ["<c-y>"] = "preview_scrolling_up",
      },
      i = {
        ["<c-b>"] = "delete_buffer",
        -- unified open scheme (see helpers above)
        ["<cr>"]  = select_with_line,      -- open in current window
        ["<M-h>"] = split_left,            -- split → left
        ["<M-j>"] = split_down,            -- split → below
        ["<M-k>"] = split_up,              -- split → above
        ["<M-l>"] = split_right,           -- split → right
        ["<M-w>"] = open_in_picked_window, -- pick target window
        ["<c-t>"] = select_tab,            -- new tab
        ["<C-S-u>"] = "results_scrolling_up",
        ["<C-S-d>"] = "results_scrolling_down",
        ["<c-f>"] = "preview_scrolling_down",
        ["<c-y>"] = "preview_scrolling_up",
      },
    },
  },
  extensions = {
    undo = { side_by_side = true },
    live_grep_args = {
      -- A prompt not starting with ' " or - is treated as one literal pattern,
      -- so plain searches behave exactly like stock live_grep; flags kick in
      -- only when quoted: "text" -t lua / -g *.md / --iglob !*_test.go
      auto_quoting = true,
      mappings = {
        i = {
          -- quote the current prompt so a flag can be appended
          ["<C-k>"] = function(...)
            return require("telescope-live-grep-args.actions").quote_prompt()(...)
          end,
          ["<C-g>"] = function(...)
            return require("telescope-live-grep-args.actions").quote_prompt({ postfix = " --iglob " })(...)
          end,
          -- builtin live_grep gets this mapping out of the box, but lga is a
          -- separate picker and doesn't inherit it — wire telescope's action up
          ["<C-Space>"] = actions.to_fuzzy_refine,
        },
      },
    },
  },
})

pcall(telescope.load_extension, "undo")
vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>", { desc = " Undo history" })

-- If you want both scrolling speeds, it might be easier to write your own custom slow scrolling action. Something like this:
-- https://github.com/nvim-telescope/telescope.nvim/issues/2602
-- local state = require("telescope.state")
-- local action_state = require("telescope.actions.state")
--
-- local slow_scroll = function(prompt_bufnr, direction)
--   local previewer = action_state.get_current_picker(prompt_bufnr).previewer
--   local status = state.get_status(prompt_bufnr)
--
--   -- Check if we actually have a previewer and a preview window
--   if type(previewer) ~= "table" or previewer.scroll_fn == nil or status.preview_win == nil then
--     return
--   end
--
--     previewer:scroll_fn(1 * direction)
-- end

pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "live_grep_args")
-- pcall(require('telescope').load_extension, 'gh')

-- See `:help telescope.builtin`
local t = require("telescope.builtin")

local colorscheme_fuzzy_find = function() t.colorscheme({ enable_preview = true }); end
-- `default_text` pre-fills the prompt (used by the visual-mode <leader>fb below);
-- nil for the plain normal-mode mapping, which opens with an empty prompt.
local current_buffer_fuzzy_find = function(default_text)
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  t.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
    winblend = 10,
    previewer = true,
    default_text = default_text,
  })
end

-- Full fuzzy buffer list. The quick letter-picker lives on <leader><space>
-- (user/bufpick.lua); this is the fallback for "more buffers than letters" and for
-- when you actually do want to search by name.
vim.keymap.set('n', "<leader>fB", function()
  -- The buffers picker errors ("No buffers found with the provided options")
  -- when there are no listed buffers — e.g. on the dashboard / a fresh session.
  -- Fall back to find_files so <leader><leader> always does something useful.
  local has_listed = false
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted then has_listed = true; break end
  end
  if has_listed then t.buffers() else t.find_files() end
end, {desc="󰕸 buffers list"})
vim.keymap.set('n', '<leader>fb', current_buffer_fuzzy_find, {desc="󰕸  buffer"})
vim.keymap.set('n', "<leader>ff", t.find_files, {desc=" Files"})
vim.keymap.set('n', "<leader>fv", t.git_files, {desc="  Git files"})
-- live-grep-args: plain text searches work as before (auto_quoting wraps the
-- whole prompt), and rg flags can be typed in the prompt once the pattern is
-- quoted: "text" -t lua / -g *.md. <C-k> quotes the prompt, <C-g> quotes it and
-- appends --iglob. The picker takes rg's base args via vimgrep_arguments (not
-- additional_args like builtin live_grep), so --hidden/.git glob live there.
vim.keymap.set('n', "<leader>fg", function()
  if pcall(telescope.load_extension, "live_grep_args") then
    telescope.extensions.live_grep_args.live_grep_args({
      vimgrep_arguments = {
        "rg", "--color=never", "--no-heading", "--with-filename",
        "--line-number", "--column", "--smart-case",
        "--hidden", "--glob", "!**/.git/*",
      },
    })
  else
    t.live_grep({ additional_args = { "--hidden", "--glob", "!**/.git/*" } })
  end
end, {desc=" grep"})
vim.keymap.set('n', "<leader>fw", function()
  t.grep_string({ additional_args = { "--hidden", "--glob", "!**/.git/*" } })
end, {desc="  Word under cursor"})
vim.keymap.set('n', "<leader>fd", t.diagnostics, {desc=" Diagnostics"})
vim.keymap.set('n', "<leader>fs", t.registers, {desc="registers"})
vim.keymap.set('n', "<leader>fr", t.resume, {desc=" Resume search"})
vim.keymap.set('n', "<leader>.t", t.help_tags, {desc="󰋖 help tags"})
vim.keymap.set('n', "<leader>fM", t.man_pages, {desc="󰾙 man pages"})
vim.keymap.set('n', "<leader>fK", t.keymaps, {desc="  Keymaps (all)"})
vim.keymap.set('n', "<leader>fo", t.oldfiles, {desc="Recently Opened Files"})
-- git_status remaps <Tab> to stage/unstage, breaking the usual telescope
-- navigation muscle-memory. Restore <Tab>/<S-Tab> as selection movement (like
-- every other picker) and move staging to <C-s>. The builtin's attach_mappings
-- runs first — it sets up git_staging_toggle + its refresh-on-stage post hook
-- (see telescope/pickers.lua:1545, which chains ours after theirs) — so staging
-- still refreshes the list; ours just overrides the keys afterwards.
-- Note: <C-s> can be swallowed by terminal flow-control (XOFF); if it does
-- nothing, either `stty -ixon` in your shell or swap it for <M-s> below.
vim.keymap.set('n', "<leader>fc", function()
  local a = require("telescope.actions")
  t.git_status({
    attach_mappings = function(_, map)
      map({ "i", "n" }, "<Tab>", a.toggle_selection + a.move_selection_worse)
      map({ "i", "n" }, "<S-Tab>", a.toggle_selection + a.move_selection_better)
      map({ "i", "n" }, "<C-s>", a.git_staging_toggle) -- stage/unstage file
      return true
    end,
  })
end, {desc=" Changed files (git status)"})
vim.keymap.set('n', "<leader>fj", t.jumplist, {desc=" Jumplist"})
vim.keymap.set('n', "<leader>fm", t.marks, {desc=" Marks"})
vim.keymap.set('n', "<leader>fq", t.quickfix, {desc=" Quickfix list"})
vim.keymap.set('n', "<leader>fl", t.loclist, {desc=" Location list"})
vim.keymap.set('n', "<leader>ft", t.treesitter, {desc=" Treesitter symbols"})
vim.keymap.set('n', "<leader>fp", t.builtin, {desc=" Telescope pickers"})
vim.keymap.set('n', "<leader>fe", t.symbols, {desc=" Symbols (emoji/unicode)"})
vim.keymap.set('n', "<leader>f:", t.command_history, {desc=" Command history"})
vim.keymap.set('n', "<leader>f/", t.search_history, {desc=" Search history"})
vim.keymap.set('n', "<leader>.O", t.vim_options, {desc="Vim options"})
vim.keymap.set('n', "<leader>fx", t.commands, {desc=" commands"})
vim.keymap.set('n', "<leader>.h", t.highlights, {desc="highlights"})
vim.keymap.set('n', "<leader>.c", colorscheme_fuzzy_find, {desc=" Colorscheme with preview"})
-- TODO income/outgoing calls
-- FIXME document symbols select kind

vim.keymap.set("i", "<C-r>", t.registers, {desc='registers'})

-- ── Visual-mode search: take the selection as the search term ──────────────────
--   <leader>fs   grep it project-wide      (visual twin of <leader>fw)
--   <leader>fb   fuzzy-find it in the buffer (visual twin of <leader>fb)
--   <leader>f/   plain / search, n/N to walk the matches
--
-- The selection is read with getpos('v') / getpos('.'), which are still valid
-- inside an x-mode mapping's Lua callback — unlike the '< '> marks, which Neovim
-- only writes *after* visual mode ends. So grab the region first, then drop out of
-- visual mode before anything else takes over the screen.
local function take_selection()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  vim.cmd("normal! \27") -- leave visual mode
  return lines
end

-- Both telescope pickers match line by line (ripgrep for grep_string, the buffer's
-- lines for the fuzzy finder), so a multi-line selection can never match as a
-- whole: use the first line and say so, instead of silently searching for
-- something other than what was selected. Returns nil when there is nothing to
-- search for.
local function selection_line(what)
  local lines = take_selection()
  if #lines > 1 then
    vim.notify(what .. ": multi-line selection, using the first line only", vim.log.levels.WARN)
  end
  local text = lines[1] or ""
  if text == "" then
    vim.notify(what .. ": selection is empty", vim.log.levels.WARN)
    return nil
  end
  return text
end

-- grep_string escapes regex metacharacters unless use_regex is set, so the
-- selection is searched literally.
vim.keymap.set('x', "<leader>fs", function()
  local text = selection_line("grep selection")
  if text then t.grep_string({ search = text }) end
end, { desc = "  Grep selection" })

-- Pre-fill the current-buffer fuzzy finder. This one stays fuzzy on purpose: the
-- selection seeds the prompt and can then be edited/loosened, unlike the two
-- literal searches around it.
vim.keymap.set('x', '<leader>fb', function()
  local text = selection_line("buffer search")
  if text then current_buffer_fuzzy_find(text) end
end, { desc = "󰕸  Selection in buffer" })

-- Native / search for the selection — the "visual mode *" that vim lacks.
-- Unlike the pickers above this handles multi-line selections: \n in a search
-- pattern matches a line break, so the whole region stays searchable.
-- \V (very nomagic) makes everything literal except the backslash; / is escaped
-- too, so recalling the pattern from history with / <Up> can't be cut short by it.
-- The pattern goes into both @/ and the search history, so n/N, q/ and :%s//…
-- behave exactly as if it had been typed.
vim.keymap.set('x', "<leader>f/", function()
  local lines = take_selection()
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    vim.notify("search selection: selection is empty", vim.log.levels.WARN)
    return
  end
  for i, line in ipairs(lines) do
    lines[i] = vim.fn.escape(line, "\\/")
  end
  local pattern = "\\V" .. table.concat(lines, "\\n")
  vim.fn.setreg("/", pattern)
  vim.fn.histadd("search", pattern)
  vim.o.hlsearch = true
  -- Jump to the next match, like / does. Fails only on 'nowrapscan' with no match
  -- further down; the selection itself is still highlighted where it is.
  if not pcall(vim.cmd, "normal! n") then
    vim.notify("search selection: no further match", vim.log.levels.INFO)
  end
end, { desc = "  Search selection (/)" })
