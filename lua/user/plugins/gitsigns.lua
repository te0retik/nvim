local ok, gitsigns = pcall(require, "gitsigns")
if not ok then
  require('user.utils').info('skipped gitsigns')
  return
end

gitsigns.setup({
  signs              = {},
  -- Show staged hunks too (dimmed sign variants, GitSignsStaged* groups) and
  -- populate the staged-hunks cache that the scrollbar/minimap handlers read.
  signs_staged_enable = true,
  signcolumn         = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl              = true,  -- Toggle with `:Gitsigns toggle_numhl`
  linehl             = false, -- Toggle with `:Gitsigns toggle_linehl`
  current_line_blame = true,  -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = { delay = 1000 }, -- 1s before the blame virt-text appears
  watch_gitdir       = { interval = 1000, follow_files = true },
  -- gitsigns defaults this to false and then refuses to attach to an untracked
  -- file at all — which silently kills every buffer-local mapping from on_attach
  -- below (gj/gk, ih, ]c/[c) in exactly the files that are new in a worktree.
  -- With it on, an untracked file shows up as one all-added hunk and the hunk
  -- mappings keep working there.
  attach_to_untracked = true,
  on_attach          = function(bufnr)
    -- Buffer-local hunk navigation only.
    -- target = "all" walks staged AND unstaged hunks. gitsigns defaults to
    -- "unstaged", i.e. worktree-vs-index, so a file whose changes are already
    -- staged has an empty diff and navigation just says "No hunks" — even though
    -- the file plainly differs from HEAD. "all" makes gj/gk mean "next change in
    -- this file", regardless of which side of the index it sits on.
    -- (Kept as a nav option rather than change_base("HEAD"): the diff base stays
    -- the index, so the signs keep distinguishing staged from unstaged and
    -- <leader>gs / <leader>gr still act on the right thing.)
    vim.keymap.set("n", "gj", function() gitsigns.nav_hunk("next", { target = "all" }) end, { buffer = bufnr, desc = "Next hunk" })
    vim.keymap.set("n", "gk", function() gitsigns.nav_hunk("prev", { target = "all" }) end, { buffer = bufnr, desc = "Prev hunk" })
    vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>",
      { buffer = bufnr, desc = "Select Hunk" })

    -- diff-aware ]c / [c
    vim.keymap.set({ "n", "v" }, "]c", function()
      if vim.wo.diff then return "]c" end
      vim.schedule(function() gitsigns.nav_hunk("next", { target = "all" }) end)
      return "<Ignore>"
    end, { expr = true, buffer = bufnr, desc = "Jump to next hunk" })

    vim.keymap.set({ "n", "v" }, "[c", function()
      if vim.wo.diff then return "[c" end
      vim.schedule(function() gitsigns.nav_hunk("prev", { target = "all" }) end)
      return "<Ignore>"
    end, { expr = true, buffer = bufnr, desc = "Jump to previous hunk" })
  end,
})

-- Global keymaps — always shown under <leader>g/<leader>g., even in non-git
-- buffers. gitsigns functions no-op safely when no git attach is present.
local function setkey(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

-- reset_hunk() only looks at the worktree-vs-index diff, while the signs and
-- <leader>gp's preview fall back to staged hunks — so on a hunk that's already
-- in the index it answers "No hunk to reset" even though a change is plainly
-- shown. Make reset mean "revert what the sign shows": when the cursor hunk is
-- staged-only, unstage it first (stage_hunk is a toggle) and reset once the
-- callback confirms the cache refreshed. When unstaged and staged hunks overlap
-- on the same line, the unstaged one is reset first (same preference as the
-- preview); a second <leader>gr then reverts the staged remainder.
local function staged_only_hunk_at_cursor()
  local bcache = require("gitsigns.cache").cache[vim.api.nvim_get_current_buf()]
  if not bcache then return false end
  local Hunks = require("gitsigns.hunks")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line_count = vim.api.nvim_buf_line_count(0)
  return Hunks.find_hunk(lnum, bcache.hunks, line_count) == nil
     and Hunks.find_hunk(lnum, bcache.hunks_staged, line_count) ~= nil
end

setkey("<leader>gs", function() gitsigns.stage_hunk() end,         "Stage hunk")
setkey("<leader>gS", function() gitsigns.stage_buffer() end,       "Stage buffer")
setkey("<leader>gr", function()
  if staged_only_hunk_at_cursor() then
    gitsigns.stage_hunk(nil, nil, function() gitsigns.reset_hunk() end)
  else
    gitsigns.reset_hunk()
  end
end, "Reset hunk")
-- Same idea buffer-wide: with staged hunks present, unstage the whole file
-- first so reset_buffer() reverts everything back to HEAD, not just to the index.
setkey("<leader>gR", function()
  local bcache = require("gitsigns.cache").cache[vim.api.nvim_get_current_buf()]
  if bcache and bcache.hunks_staged and #bcache.hunks_staged > 0 then
    gitsigns.reset_buffer_index(function() gitsigns.reset_buffer() end)
  else
    gitsigns.reset_buffer()
  end
end, "Reset buffer")
setkey("<leader>gI", function() gitsigns.reset_buffer_index() end, "Reset buffer index")
setkey("<leader>gu", function() gitsigns.undo_stage_hunk() end,    "Undo stage hunk")
setkey("<leader>gD", function() gitsigns.diffthis() end,           "Diff this")

-- Close the gitsigns `diffthis` scratch window cleanly. Diffview already maps
-- `q` -> close inside its own windows, so we only need to handle the gitsigns
-- diff. Buffer-local: `q` is only rebound inside the scratch buffer itself, so
-- plain `:q` and normal-mode `q` (macro record) are left untouched everywhere else.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("GitsignsDiffQuit", { clear = true }),
  pattern = "gitsigns://*",
  callback = function(ev)
    vim.keymap.set("n", "q", function()
      vim.cmd("diffoff!")     -- turn diff off across the tab (incl. the real file)
      pcall(vim.cmd, "close") -- close the scratch window we're in
    end, { buffer = ev.buf, desc = "Close gitsigns diff" })
  end,
})

setkey("<leader>gp", function() gitsigns.preview_hunk() end,       "Preview hunk")
setkey("<leader>ge", function() gitsigns.refresh() end,            "Refresh")

setkey("<leader>g.b", function() gitsigns.toggle_current_line_blame() end, "Toggle current line blame")
setkey("<leader>g.j", function() gitsigns.toggle_deleted() end,            "Toggle deleted")
setkey("<leader>g.l", function() gitsigns.toggle_linehl() end,             "Toggle linehl")
setkey("<leader>g.n", function() gitsigns.toggle_numhl() end,              "Toggle numhl")
setkey("<leader>g.w", function() gitsigns.toggle_word_diff() end,          "Toggle word diff")
setkey("<leader>g.i", function() gitsigns.toggle_signs() end,              "Toggle signs")

-- which-key groups + live-state badges (registered separately so they merge
-- with the plain vim.keymap.set descs above)
local gs_cfg = require("gitsigns.config").config
local function badge(v) return v and "[ON ]" or "[off]" end
local function lbl(name, key)
  return function() return badge(gs_cfg[key]) .. " " .. name end
end

local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
  wk.add({
    { "<leader>g.",  group = "+ 󰊢 sign settings" },
    { "<leader>g.b", desc = lbl("Current line blame", "current_line_blame") },
    { "<leader>g.j", desc = lbl("Deleted",            "show_deleted") },
    { "<leader>g.l", desc = lbl("Linehl",             "linehl") },
    { "<leader>g.n", desc = lbl("Numhl",              "numhl") },
    { "<leader>g.w", desc = lbl("Word diff",          "word_diff") },
    { "<leader>g.i", desc = lbl("Signs",              "signcolumn") },
  })
end
