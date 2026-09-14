-- Visual buffer switcher: every other listed buffer gets a letter, one keypress
-- jumps there. Reading names in a fuzzy list is the thing this avoids, so the
-- letters are the interface and the names are only there to orient you.
--
-- The alphabet is nvim-window-picker's `selection_chars`
-- (init/plugins/navigation.lua), so the same letter under the same finger means
-- "go there" whether you are picking a window (<leader>ww) or a buffer.
local M = {}

-- Home row first, exactly window-picker's order.
local CHARS = "FJDKSLA;CMRUEIWOQP"

local ns = vim.api.nvim_create_namespace("user.bufpick")
-- Separate namespace so the selection bar can be cleared on every keypress
-- without wiping the label/name/path highlights, which never change.
local ns_sel = vim.api.nvim_create_namespace("user.bufpick.sel")

---Listed buffers except the current one, most recently used first, each with a
---letter. The current buffer is left out on purpose: you never switch to where
---you already are, and dropping it makes the first letter the alternate buffer
---(what <C-^> would do).
---@return {label:string, bufnr:integer, name:string, dir:string, modified:boolean}[]
function M.entries()
  local cur = vim.api.nvim_get_current_buf()
  local bufs = vim.tbl_filter(function(b)
    return b.bufnr ~= cur
  end, vim.fn.getbufinfo({ buflisted = 1 }))

  table.sort(bufs, function(a, b) return a.lastused > b.lastused end)

  local out = {}
  for i, b in ipairs(bufs) do
    local ch = CHARS:sub(i, i)
    -- More buffers than letters: the tail is unreachable here by design — that is
    -- what the full picker on <leader>fB is for.
    if ch == "" then break end
    out[i] = {
      label = ch,
      bufnr = b.bufnr,
      name = b.name ~= "" and vim.fn.fnamemodify(b.name, ":t") or "[No Name]",
      dir = b.name ~= "" and vim.fn.fnamemodify(b.name, ":~:.:h") or "",
      modified = b.changed == 1,
    }
  end
  return out
end

---@param items table[] from M.entries()
---@return string[] lines, table[] per-line highlights as {start_col, end_col, hl}
local function render(items)
  local name_w = 0
  for _, it in ipairs(items) do
    name_w = math.max(name_w, #it.name)
  end

  local lines, marks = {}, {}
  for i, it in ipairs(items) do
    local label = " " .. it.label .. "  "
    local name = it.name .. string.rep(" ", name_w - #it.name)
    local tail = "  " .. it.dir .. (it.modified and "  ●" or "")
    lines[i] = label .. name .. tail
    marks[i] = {
      { 0, #label, "Special" },
      { #label, #label + #it.name, it.modified and "WarningMsg" or "Normal" },
      { #label + #name, #lines[i], "Comment" },
    }
  end
  return lines, marks
end

---The entry labelled `key`, if any. Case-insensitive: the labels are upper case
---for legibility, but nobody presses Shift to change buffers.
---@param key string
---@param items? table[] the list the letters were drawn from; re-read if omitted
---@return table|nil
function M.find(key, items)
  for _, it in ipairs(items or M.entries()) do
    if it.label:lower() == key:lower() then return it end
  end
end

---Switch to the buffer labelled `key`.
---@return boolean switched
function M.jump(key, items)
  local it = M.find(key, items)
  if it and vim.api.nvim_buf_is_valid(it.bufnr) then
    vim.api.nvim_set_current_buf(it.bufnr)
    return true
  end
  return false
end

function M.pick()
  local items = M.entries()
  if #items == 0 then
    vim.notify("bufpick: no other listed buffer", vim.log.levels.INFO)
    return
  end

  local lines, marks = render(items)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for row, cols in ipairs(marks) do
    for _, m in ipairs(cols) do
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, m[1], { end_col = m[2], hl_group = m[3] })
    end
  end
  vim.bo[buf].modifiable = false

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = math.max(0, math.floor((vim.o.lines - #lines) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    width = width + 1,
    height = #lines,
    style = "minimal",
    border = "rounded",
    title = " buffers ",
    title_pos = "center",
    zindex = 200,
    noautocmd = true,
  })

  -- Walk the list with <Tab>/<S-Tab> (or the arrows) and open with <CR>. The
  -- letters still jump directly, so the fast path costs nothing extra.
  -- j/k are deliberately NOT movement keys: J, K, D, S, L, A… are labels, and
  -- input is matched case-insensitively, so j would have to mean both "down" and
  -- "go to the buffer labelled J".
  local KEY = {
    tab  = vim.keycode("<Tab>"),  stab = vim.keycode("<S-Tab>"),
    down = vim.keycode("<Down>"), up   = vim.keycode("<Up>"),
    cr   = vim.keycode("<CR>"),   esc  = vim.keycode("<Esc>"),
  }

  local sel, chosen = 1, nil
  while true do
    -- The float is only painted on a redraw, and getcharstr() blocks before one
    -- would happen on its own — without this the window stays invisible.
    vim.api.nvim_buf_clear_namespace(buf, ns_sel, 0, -1)
    vim.api.nvim_buf_set_extmark(buf, ns_sel, sel - 1, 0, { line_hl_group = "CursorLine" })
    vim.cmd("redraw")

    -- pcall: getcharstr() throws on <C-c>, which should just cancel.
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok or key == "" or key == KEY.esc or key:lower() == "q" then break end

    if key == KEY.tab or key == KEY.down then
      sel = sel % #items + 1
    elseif key == KEY.stab or key == KEY.up then
      sel = (sel - 2) % #items + 1
    elseif key == KEY.cr then
      chosen = items[sel]
      break
    else
      -- A letter jumps straight there; anything else cancels silently — a mistyped
      -- key should not cost a notification you then have to dismiss.
      chosen = M.find(key, items)
      break
    end
  end

  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  if chosen and vim.api.nvim_buf_is_valid(chosen.bufnr) then
    vim.api.nvim_set_current_buf(chosen.bufnr)
  end
end

require("user.utils").nnoremap("<leader><space>", M.pick, "󰕸 Pick buffer (letters)")

return M
