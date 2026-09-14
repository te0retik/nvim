local M = {}

-- The cheatsheet is generated from the LIVE keymaps of the running config, so
-- keys and their descriptions are never duplicated here: add/rename a mapping
-- and it shows up (or updates) automatically on next open. Only keys that are
-- NOT real global keymaps are listed statically per section — vim-native
-- commands (<C-w>hjkl, folds, …) and buffer-local/transient keys (telescope &
-- nvim-tree splits, the git-status stage key, lazygit) that there's nothing to
-- introspect from globally.
--
-- Config-defined mappings are prefixed with the CUSTOM icon; vim-native keys are
-- not — so you can tell at a glance what's yours vs vanilla vim.

local CUSTOM = "" -- marks a config-defined (non-vanilla-vim) mapping

-- Sections in priority order: each auto-collected keymap lands in the FIRST
-- section whose match(lhs, desc) is true; unmatched keymaps are skipped.
-- `native` holds static rows for keys that aren't global keymaps (no icon).
local sections = {
  {
    title = "  FOLDS",
    match = function(lhs, d) return lhs:match("^z") or d:match("[Ff]old") end,
    native = {
      { "za / zc", "toggle / close fold under cursor" },
      { "zR / zM", "open / close ALL folds" },
      { "zr / zm", "open / close one fold level" },
    },
  },
  {
    title = "  SPLITS",
    match = function(lhs, d) return lhs:match("^<leader>s[hjklvt]") end,
    native = {
      { "(picker) <CR>",        "open item in current window" },
      { "(picker) <M-h/j/k/l>", "open item in a split" },
      { "(picker) <C-t>",       "open item in a new tab" },
      { "(picker) <M-w>",       "open in a picked window" },
    },
  },
  {
    title = "  WINDOWS",
    match = function(_, d) return d:match("[Rr]esize") end,
    native = {
      { "<C-w> h/j/k/l", "move between windows" },
      { "<C-w> =",       "equalize window sizes" },
      { "<C-w> q",       "close window" },
    },
  },
  {
    title = "󰓩  TABS",
    -- whole word "tab" only, so "Database" etc. don't leak in
    match = function(_, d)
      d = d:lower()
      return d:match("%f[%a]tab%f[%A]") ~= nil and not d:match("terminal")
    end,
  },
  {
    title = "  GIT",
    match = function(lhs, d)
      return lhs:match("^<leader>g") or d:match("[Hh]unk") or d:match("[Ss]tage") or d:match("[Gg]it")
    end,
    native = {
      { "<C-s>", "stage / unstage file in the git-status picker (<leader>fc)" },
    },
  },
  {
    title = "󰒓  OTHER (non-obvious)",
    match = function(_, d)
      d = d:lower()
      for _, kw in ipairs({
        "paste", "comment", "save", "quit", "close buffer", "terminal",
        "session", "copy", "reload", "hlsearch", "clear",
      }) do
        if d:find(kw, 1, true) then return true end
      end
      return false
    end,
    native = {
      { "lazygit <Esc> / q", "back-cancel / quit  (<C-u>/<C-d> scroll diff)" },
    },
  },
}

-- nvim_get_keymap reports the space leader as a literal leading " " and window
-- commands as "<C-W>"; make both readable.
local function pretty(lhs)
  if lhs:sub(1, 1) == " " then lhs = "<leader>" .. lhs:sub(2) end
  lhs = lhs:gsub("^<Space>", "<leader>")
  lhs = lhs:gsub("^<C%-W>", "<C-w>")
  return lhs
end

-- Pull live keymaps (n/x/t), dedup by lhs, drop the first matching section.
local function collect()
  for _, s in ipairs(sections) do s.rows = {} end
  local seen = {}
  for _, mode in ipairs({ "n", "x", "t" }) do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      if m.desc and m.desc ~= "" then
        local lhs = pretty(m.lhs)
        if not seen[lhs] then
          seen[lhs] = true
          for _, s in ipairs(sections) do
            if s.match(lhs, m.desc) then
              table.insert(s.rows, { lhs, m.desc })
              break
            end
          end
        end
      end
    end
  end
end

local dw = vim.fn.strdisplaywidth
local GUTTER = 4 -- blank columns between tiles

-- Render one section into a "tile": an array of lines (title + aligned rows).
local function render_tile(s)
  local icon_w = dw(CUSTOM)
  local mark_custom = "  " .. CUSTOM .. " "
  local mark_native = "  " .. string.rep(" ", icon_w) .. " " -- same width, no icon
  local kw = 0 -- key column width, per tile
  for _, r in ipairs(s.rows) do kw = math.max(kw, dw(r[1])) end
  for _, r in ipairs(s.native or {}) do kw = math.max(kw, dw(r[1])) end
  local function line(mark, r)
    return mark .. r[1] .. string.rep(" ", kw - dw(r[1])) .. "  " .. r[2]
  end
  table.sort(s.rows, function(a, b) return a[1] < b[1] end)
  local out = { s.title }
  for _, r in ipairs(s.rows) do out[#out + 1] = line(mark_custom, r) end
  for _, r in ipairs(s.native or {}) do out[#out + 1] = line(mark_native, r) end
  return out
end

-- Fill `ncols` columns top-to-bottom with a balanced height budget, so tiles
-- keep their reading order. Returns a list of columns (each a list of lines).
local function distribute(tiles, ncols)
  local total_h = 0
  for _, t in ipairs(tiles) do total_h = total_h + #t + 1 end
  local budget = math.ceil(total_h / ncols)
  local cols, c = { {} }, 1
  for _, t in ipairs(tiles) do
    if #cols[c] > 0 and #cols[c] + #t > budget and c < ncols then
      c = c + 1
      cols[c] = {}
    end
    for _, l in ipairs(t) do table.insert(cols[c], l) end
    table.insert(cols[c], "") -- gap after each tile
  end
  return cols
end

local function widths_of(cols)
  local ws, total = {}, 0
  for i, col in ipairs(cols) do
    local w = 0
    for _, l in ipairs(col) do w = math.max(w, dw(l)) end
    ws[i], total = w, total + w
  end
  return ws, total + GUTTER * math.max(0, #cols - 1)
end

-- Variable-width columns: pick the largest column count whose *actual* total
-- width (sum of each column's widest line + gutters) fits max_width. Narrow
-- tiles get narrow columns, so more of them pack in than with a uniform width.
local function layout(tiles, max_width)
  local cols, ws
  for ncols = #tiles, 1, -1 do
    local try = distribute(tiles, ncols)
    if #try == ncols then
      local w, total = widths_of(try)
      if total <= max_width or ncols == 1 then
        cols, ws = try, w
        break
      end
    end
  end
  if not cols then cols, ws = distribute(tiles, 1), select(1, widths_of(distribute(tiles, 1))) end

  local height = 0
  for _, col in ipairs(cols) do height = math.max(height, #col) end
  local sep = string.rep(" ", GUTTER)
  local out = {}
  for r = 1, height do
    local parts = {}
    for i = 1, #cols do
      local l = cols[i][r] or ""
      parts[i] = l .. string.rep(" ", ws[i] - dw(l))
    end
    out[#out + 1] = (table.concat(parts, sep):gsub("%s+$", ""))
  end
  return out
end

local function build_lines(max_width)
  collect()
  local tiles = {}
  for _, s in ipairs(sections) do
    if #s.rows > 0 or (s.native and #s.native > 0) then
      tiles[#tiles + 1] = render_tile(s)
    end
  end

  local lines = { "  ⌨  Cheatsheet    " .. CUSTOM .. " = custom mapping", "" }
  for _, l in ipairs(layout(tiles, max_width)) do lines[#lines + 1] = l end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  press  q  or  <Esc>  to close"
  return lines
end

function M.open()
  local max_width = math.max(40, vim.o.columns - 8)
  local lines = build_lines(max_width)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "cheatsheet"

  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  width = math.min(width + 3, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 4)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2 - 1),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Cheatsheet ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function() pcall(vim.api.nvim_win_close, win, true) end,
      { buffer = buf, nowait = true, silent = true, desc = "close cheatsheet" })
  end
end

return M
