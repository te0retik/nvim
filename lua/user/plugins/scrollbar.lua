local ok, scrollbar = pcall(require, "scrollbar")
if not ok then
  require("user.utils").info("skipped scrollbar")
  return
end

scrollbar.setup({
  hide_if_all_visible = true, -- no bar when the whole buffer fits on screen
  excluded_filetypes = {
    "NvimTree", "lazy", "TelescopePrompt", "neominimap", "noice", "blank",
  },
  marks = {
    -- default is a barely-visible "•" with Normal fg — make the cursor mark a
    -- solid block so it stands out on the bar
    Cursor = { text = "█", highlight = "Title" },
    -- default "┆" (thin dashed bar) is nearly invisible on the bar; use a half
    -- block: solid enough to see, narrow enough to keep the handle visible
    GitAdd = { text = "▐" },
    GitChange = { text = "▐" },
    -- staged hunks (custom handler below) — dimmed GitSignsStaged* colors
    GitAddStaged = { text = "▐", priority = 8, highlight = "GitSignsStagedAdd" },
    GitChangeStaged = { text = "▐", priority = 8, highlight = "GitSignsStagedChange" },
    GitDeleteStaged = { text = "▁", priority = 8, highlight = "GitSignsStagedDelete" },
  },
  handlers = {
    cursor = true,
    diagnostic = true,
    gitsigns = true,
    search = true, -- via hlslens (search handler below)
  },
})

-- Search marks on the bar. This calls hlslens.setup() itself with an override
-- that feeds matches to the scrollbar — don't call hlslens.setup() separately,
-- it would drop that override.
require("scrollbar.handlers.gitsigns").setup()

-- Staged hunks on the bar. The stock gitsigns handler only reads worktree
-- hunks (gitsigns.get_hunks); staged ones live in gitsigns' cache (populated
-- because signs_staged_enable is on — see user/plugins/gitsigns.lua). Custom
-- handlers run on every render pass, so no extra autocmd is needed.
require("scrollbar.handlers").register("gitsigns_staged", function(bufnr)
  local ok, gs_cache = pcall(require, "gitsigns.cache")
  local cached = ok and gs_cache.cache[bufnr] or nil
  local hunks = cached and cached.hunks_staged or nil
  if not hunks then return {} end
  local cfg = require("scrollbar.config").get()
  local marks = {}
  for _, hunk in ipairs(hunks) do
    if hunk.type == "delete" then
      table.insert(marks, {
        line = math.max(0, hunk.added.start - 1),
        text = cfg.marks.GitDeleteStaged.text,
        type = "GitDeleteStaged",
        level = 1,
      })
    else
      local mtype = hunk.type == "add" and "GitAddStaged" or "GitChangeStaged"
      for line = hunk.added.start, hunk.added.start + math.max(0, hunk.added.count - 1) do
        table.insert(marks, {
          line = line - 1,
          text = cfg.marks[mtype].text,
          type = mtype,
          level = 1,
        })
      end
    end
  end
  return marks
end)

-- Custom handlers only re-run on WinScrolled; refresh staged marks right when
-- gitsigns recomputes hunks (stage/unstage/edit), like the stock handler does.
vim.api.nvim_create_autocmd("User", {
  pattern = "GitSignsUpdate",
  group = vim.api.nvim_create_augroup("user_scrollbar_staged", { clear = true }),
  callback = function()
    require("scrollbar.handlers").show()
    require("scrollbar").throttled_render()
  end,
})

-- GitSignsStaged* groups are derived by gitsigns, which may load after this
-- file (both are VeryLazy) — re-derive the Scrollbar* highlights once it's up.
vim.defer_fn(function() pcall(require("scrollbar.utils").set_highlights) end, 1500)
require("scrollbar.handlers.search").setup({
  -- no calm_down: it wipes the lens+highlight as soon as the cursor leaves the
  -- match, which reads as "hlslens resets on any navigation". Clear manually
  -- with <leader>fC (:nohlsearch) or toggle hlslens with <leader>.f instead.

  -- Align all lenses in one vertical column near the window's right edge
  -- (default puts them at each line's eol, so they zigzag with line length).
  -- Same text as the stock lens; only the placement differs: virt_text_win_col
  -- pins the virtual text to a fixed window column. Long lines are drawn over
  -- at that column — the price of the alignment.
  override_lens = function(render, posList, nearest, idx, relIdx)
    local sfw = vim.v.searchforward == 1
    local absRelIdx = math.abs(relIdx)
    local indicator
    if absRelIdx > 1 then
      indicator = ("%d%s"):format(absRelIdx, sfw ~= (relIdx > 1) and "▲" or "▼")
    elseif absRelIdx == 1 then
      indicator = sfw ~= (relIdx == 1) and "▲" or "▼"
    else
      indicator = ""
    end
    local lnum = posList[idx][1]
    -- Fixed-width layout so every character keeps its column while jumping
    -- between matches: [<ind:3><idx:cw>/<cnt:cw>]. Padding must go by display
    -- width (▲/▼ are multi-byte, so %3s would misalign), hence pad_left.
    local function pad_left(s, w)
      local d = w - vim.fn.strdisplaywidth(s)
      return (d > 0 and (" "):rep(d) or "") .. s
    end
    local cnt = #posList
    local cw = #tostring(cnt) -- digits in the total count
    -- shared prefix "[ind idx" is fixed-width for every lens; only the nearest
    -- one appends its "/total" tail (no empty placeholder on the others)
    local text = ("[%s %s%s]"):format(
      pad_left(indicator, 3),
      pad_left(tostring(idx), cw),
      nearest and ("/" .. cnt) or ""
    )
    local chunks = { { text, nearest and "HlSearchLensNear" or "HlSearchLens" } }
    -- shift left of the minimap float when it's shown (20 cols + 1 margin,
    -- see vim.g.neominimap in init/plugins/tools.lua), else it covers the lens
    local map_pad = 0
    local mm_ok, mm = pcall(require, "neominimap.api")
    if mm_ok and mm.enabled() then map_pad = 21 end
    local lens_col = math.max(vim.api.nvim_win_get_width(0) - 18 - map_pad, 20)
    render:setVirtText(0, lnum - 1, chunks, { virt_text_win_col = lens_col })
  end,
})

-- The handler above only patches hlslens' config table — it never enables the
-- plugin itself (start() is a no-op while disabled). Enable it explicitly;
-- setup() must come after the handler so the patched config survives.
require("hlslens").setup()

-- hlslens only renders while "searching": wrap n/N/*/# so every jump refreshes
-- the lens (the standard hlslens recipe).
local kopts = { noremap = true, silent = true }
vim.keymap.set("n", "n",
  [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.keymap.set("n", "N",
  [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.keymap.set("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.keymap.set("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.keymap.set("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)

-- ── Toggles (<leader>. settings group) ──────────────────────────────────────
-- scrollbar and minimap each toggle on their own key; <leader>.v cycles
-- bar → map → off for one-key switching between them.

-- ── Persist bar/map visibility across restarts ──────────────────────────────
-- sessionoptions deliberately excludes "globals" (see user/plugins/persistence.lua),
-- so session files can't carry this; use a state file instead, same pattern as
-- the colorscheme persistence in user/plugins/colorscheme.lua.
-- Format: three lines, "1"/"0" for scrollbar, minimap and hlslens respectively.
local state_file = vim.fn.stdpath("state") .. "/last_viewmode"

local function view_state()
  local sb = require("scrollbar.config").get().show
  local mm_ok, mm = pcall(function() return require("neominimap.api").enabled() end)
  local hl_ok, hl = pcall(function() return require("hlslens").isEnabled() end)
  return sb, mm_ok and mm or false, hl_ok and hl or false
end

local function save_view_state()
  local sb, mm, hl = view_state()
  local fd = io.open(state_file, "w")
  if not fd then return end
  fd:write((sb and "1" or "0") .. "\n" .. (mm and "1" or "0") .. "\n" .. (hl and "1" or "0") .. "\n")
  fd:close()
end

-- Wrap a toggle so the new state lands in the state file right away (schedule:
-- neominimap applies its toggle asynchronously).
local function toggling(fn)
  return function()
    fn()
    vim.defer_fn(save_view_state, 100)
  end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("user_viewmode_persist", { clear = true }),
  callback = save_view_state,
})

local function restore_view_state()
  local fd = io.open(state_file, "r")
  if not fd then return end
  local sb, mm, hl = fd:read("*l"), fd:read("*l"), fd:read("*l")
  fd:close()
  local utils = require("scrollbar.utils")
  if sb == "0" then utils.hide() else utils.show() end
  if mm == "1" then pcall(function() require("neominimap.api").enable() end) end
  -- hlslens.setup() above enables it by default; only "off" needs restoring
  if hl == "0" then pcall(function() require("hlslens").disable() end) end
end

vim.keymap.set("n", "<leader>.s", toggling(function()
  require("scrollbar.utils").toggle()
end), { desc = "Toggle scrollbar" })

-- <leader>.m is taken by Mason (lspconfig.lua), hence the capital M
vim.keymap.set("n", "<leader>.M", toggling(function()
  require("neominimap.api").toggle()
end), { desc = "Toggle minimap" })

-- neominimap marks the cursor by highlighting the map's cursor line; its
-- default link is CursorLine, whose bg is too faint to spot on the tiny
-- braille map. Link to Visual (selection bg) instead; the plugin sets its
-- group with default=true, so this override wins regardless of load order.
-- Re-linked on ColorScheme because :colorscheme wipes custom groups.
local function minimap_cursor_hl()
  vim.api.nvim_set_hl(0, "NeominimapCursorLine", { link = "Visual" })
end
minimap_cursor_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_minimap_cursor_hl", { clear = true }),
  callback = minimap_cursor_hl,
})

-- Cycle bar → map → off. The current mode is derived from the actual plugin
-- state (not a counter), so it stays correct after restarts and lone toggles.
vim.keymap.set("n", "<leader>.v", toggling(function()
  local sb_on, mm_on = view_state()
  -- 0 off → 1 bar → 2 map → 3 both → 0 …
  local view_mode = (sb_on and mm_on and 3) or (mm_on and 2) or (sb_on and 1) or 0
  view_mode = (view_mode + 1) % 4
  local sb, mm = require("scrollbar.utils"), require("neominimap.api")
  if view_mode == 1 or view_mode == 3 then sb.show() else sb.hide() end
  if view_mode == 2 or view_mode == 3 then mm.enable() else mm.disable() end
  vim.notify(({ "scrollbar/minimap: off", "scrollbar", "minimap", "scrollbar + minimap" })[view_mode + 1])
end), { desc = "Cycle scrollbar/minimap" })

-- hlslens markers (the virtual-text match counter) on their own key. Note:
-- disabling hlslens also stops feeding search marks to the scrollbar until
-- it's toggled back on. <leader>fC (:nohlsearch) still clears everything.
vim.keymap.set("n", "<leader>.f", toggling(function()
  local hlslens = require("hlslens")
  hlslens.toggle()
  vim.notify("hlslens: " .. (hlslens.isEnabled() and "on" or "off"))
end), { desc = "Toggle hlslens markers" })

-- ── Per-window bar for duplicated buffers ────────────────────────────────────
-- The bar is drawn with buffer-local extmarks, so two windows showing the SAME
-- buffer both mirror the bar of whichever window rendered last (scrolling in
-- one appears to "move" the other's bar too). Scope the plugin's namespace to
-- each buffer's owner window — the window its bar was last computed for.
-- nvim__ns_set is a private API (documented but experimental); everything is
-- pcall-guarded so an API change just degrades back to the stock behaviour.
if vim.api.nvim__ns_set ~= nil then
  local prefix_ok, const = pcall(require, "scrollbar.const")
  local sb_ns = vim.api.nvim_create_namespace(prefix_ok and const.NAME_PREFIX or "Scrollbar")
  local owners = {} -- bufnr -> winid the bar was last rendered for

  local function rescope()
    local cur = vim.api.nvim_get_current_win()
    owners[vim.api.nvim_win_get_buf(cur)] = cur
    local wins = {}
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local b = vim.api.nvim_win_get_buf(w)
      local owner = owners[b]
      -- stale owner (window closed or showing another buffer): adopt this one
      if not owner or not vim.api.nvim_win_is_valid(owner)
          or vim.api.nvim_win_get_buf(owner) ~= b then
        owners[b] = w
        owner = w
      end
      if owner == w then wins[#wins + 1] = w end
    end
    pcall(vim.api.nvim__ns_set, sb_ns, { wins = wins })
  end

  vim.api.nvim_create_autocmd(
    { "WinEnter", "BufWinEnter", "WinClosed", "CursorMoved", "WinScrolled" },
    {
      group = vim.api.nvim_create_augroup("user_scrollbar_winscope", { clear = true }),
      callback = rescope,
    }
  )
  rescope()
end

-- Bring back whatever bar/map combination was active last time.
restore_view_state()
