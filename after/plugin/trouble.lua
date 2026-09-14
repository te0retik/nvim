local ok, trouble = pcall(require, "trouble")
if not ok then
  require('user.utils').info('skipped trouble')
  return
end

-- trouble.nvim v3 — renders LSP results (incl. call hierarchy) as a collapsible
-- tree with a preview pane and live filtering. In the list: <cr> jump · o
-- jump+close · p preview · P toggle auto-preview · zo/zc fold · f add filter ·
-- / search · r refresh · ? help · q close · S switch incoming↔outgoing.
-- Move the float into a split with the native <C-w>H/J/K/L.

-- Where the current call-hierarchy request started. trouble resolves the request
-- from the current window's buffer+cursor, and its auto-preview swaps that window
-- to the previewed caller's file (often in another file) as you browse — so `S`
-- must restore the original window, buffer AND cursor before reopening, otherwise
-- the opposite direction resolves a different symbol → "No results for calls_…".
local origin = { win = nil, buf = nil, cursor = nil }

local function switch_calls(to_mode)
  require("trouble").close()
  vim.schedule(function()
    if origin.win and vim.api.nvim_win_is_valid(origin.win)
      and origin.buf and vim.api.nvim_buf_is_valid(origin.buf) and origin.cursor then
      pcall(vim.api.nvim_set_current_win, origin.win)
      if vim.api.nvim_win_get_buf(origin.win) ~= origin.buf then
        pcall(vim.api.nvim_win_set_buf, origin.win, origin.buf) -- undo auto-preview's file swap
      end
      pcall(vim.api.nvim_win_set_cursor, origin.win, origin.cursor)
    end
    require("trouble").open({ mode = to_mode, focus = true })
  end)
end

-- Custom modes: built-in call hierarchy, but as a centred floating popup, with
-- `S` swapping direction. mode keys merge over the global defaults (zo/<cr>/… stay).
local function calls_float(base_mode, switch_to)
  return {
    mode = base_mode,
    focus = true,
    win = {
      type = "float",
      relative = "editor",
      border = "rounded",
      size = { width = 0.7, height = 0.7 },
      position = { 0.5, 0.5 },
    },
    keys = {
      S = { action = function() switch_calls(switch_to) end, desc = "switch incoming/outgoing" },
    },
  }
end

trouble.setup({
  modes = {
    calls_incoming = calls_float("lsp_incoming_calls", "calls_outgoing"),
    calls_outgoing = calls_float("lsp_outgoing_calls", "calls_incoming"),
  },
})

-- After <C-w>H/J/K/L turns the float into a split, size it to its content —
-- width to the longest line (H/L) or height to the line count (J/K) — but never
-- past a third of the screen.
local function fit_split(win, axis)
  if not vim.api.nvim_win_is_valid(win) then return end
  if vim.api.nvim_win_get_config(win).relative ~= "" then return end -- still a float; wincmd didn't split
  local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
  if axis == "width" then
    local maxw = 1
    for _, l in ipairs(lines) do
      local w = vim.fn.strdisplaywidth(l)
      if w > maxw then maxw = w end
    end
    vim.api.nvim_win_set_width(win, math.min(math.max(maxw + 1, 20), math.floor(vim.o.columns / 3)))
  else
    local n = #lines
    while n > 0 and not (lines[n] or ""):match("%S") do n = n - 1 end -- drop trailing blanks
    vim.api.nvim_win_set_height(win, math.min(math.max(n, 5), math.floor(vim.o.lines / 3)))
  end
end

local function move_and_fit(dir, axis)
  return function()
    vim.cmd("wincmd " .. dir) -- native float -> split on that side
    vim.schedule(function() pcall(fit_split, vim.api.nvim_get_current_win(), axis) end)
  end
end

-- Close the popup when it loses focus — but not when focus lands in another
-- trouble window (the `S` switch closes-then-reopens; that popup must survive).
-- Also arm the content-fitting <C-w>H/J/K/L on the popup buffer.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "trouble",
  group = vim.api.nvim_create_augroup("UserTroubleCloseOnBlur", { clear = false }),
  callback = function(ev)
    vim.api.nvim_create_autocmd("WinLeave", {
      buffer = ev.buf,
      once = true,
      callback = function()
        vim.schedule(function()
          if vim.bo[vim.api.nvim_get_current_buf()].filetype == "trouble" then return end
          pcall(function() require("trouble").close() end)
        end)
      end,
    })

    local o = { buffer = ev.buf, silent = true, nowait = true }
    vim.keymap.set("n", "<C-w>H", move_and_fit("H", "width"), o)  -- split left,  fit width
    vim.keymap.set("n", "<C-w>L", move_and_fit("L", "width"), o)  -- split right, fit width
    vim.keymap.set("n", "<C-w>J", move_and_fit("J", "height"), o) -- split below, fit height
    vim.keymap.set("n", "<C-w>K", move_and_fit("K", "height"), o) -- split above, fit height
  end,
})

-- Record the source position, then open the call-hierarchy popup. Capturing here
-- (before trouble's preview can move the cursor) is what makes `S` reliable.
local function open_calls(mode)
  origin.win = vim.api.nvim_get_current_win()
  origin.buf = vim.api.nvim_win_get_buf(origin.win)
  origin.cursor = vim.api.nvim_win_get_cursor(origin.win)
  require("trouble").toggle({ mode = mode, focus = true })
end

--   <leader>lC  incoming calls — "who calls this"  (S switches to outgoing)
--   <leader>lO  outgoing calls — "what this calls" (S switches to incoming)
vim.keymap.set("n", "<leader>lC", function() open_calls("calls_incoming") end,
  { desc = " Incoming calls (trouble)" })
vim.keymap.set("n", "<leader>lO", function() open_calls("calls_outgoing") end,
  { desc = " Outgoing calls (trouble)" })
