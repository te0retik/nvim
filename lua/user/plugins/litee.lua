local M = {}

-- Function/method nodes across the languages used here. Named ones expose a
-- `name` field; anonymous literals (func_literal, lambda, arrow_function …) do
-- not — we tell them apart at runtime by whether that field is present.
local FUNC_LIKE = {
  function_declaration = true,
  function_definition = true,  -- python/lua/c
  function_item = true,        -- rust
  method_declaration = true,
  method_definition = true,
  method_spec = true,          -- go interface method
  local_function = true,       -- lua
  function_statement = true,
  func_literal = true,         -- go anonymous
  lambda = true,               -- python
  arrow_function = true,        -- ts/js
  function_expression = true,  -- ts/js
  closure_expression = true,   -- rust
}

-- Treesitter node types that represent a call/invocation across these languages.
local CALL_NODES = {
  call_expression = true,  -- go, rust, c, ts/js
  function_call = true,    -- lua
  call = true,             -- python
  macro_invocation = true, -- rust
}

-- Move the cursor onto a node's last character. A callee (foo, foo.Bar) and an
-- assignment LHS (f, obj.h) both end at the name we want, so this lands on it
-- regardless of the expression's shape/language.
local function goto_node_end(node)
  local row, col = node:end_()
  if col > 0 then
    pcall(vim.api.nvim_win_set_cursor, 0, { row + 1, col - 1 })
  end
end

-- If the cursor is on the callee of a call (foo, foo.Bar, pkg::func …), return
-- that callee node. Anonymous callees (an IIFE) are rejected — nothing to name.
local function callee_at_cursor(node)
  local n = node
  while n do
    local p = n:parent()
    if not p then return nil end
    if CALL_NODES[p:type()] then
      local callee = p:field("function")[1] or p:field("name")[1]
      if callee ~= nil and callee == n and not FUNC_LIKE[callee:type()] then
        return callee
      end
      return nil -- in the argument list or an anonymous IIFE, not a named callee
    end
    n = p
  end
end

-- If `fn` (an anonymous function literal) is the value of an assignment or
-- declaration, return its LHS name node (f, obj.h, t.m …); nil when it is an
-- argument, an IIFE, or a return value. The LHS is the first named child of the
-- assignment container (reached through any `expression_list` wrapper), and it
-- ends at the variable/property name — so callers seek to its last char.
local function assigned_lhs(fn)
  local c = fn:parent()
  local hops = 0
  while c and hops < 3 do
    local t = c:type()
    if CALL_NODES[t] or t == "argument_list" or t == "arguments" then return nil end
    if t ~= "expression_list" then
      local lhs = c:named_child(0)
      if lhs then
        local fr, fc = fn:start()
        local lr, lc = lhs:start()
        if lr < fr or (lr == fr and lc < fc) then return lhs end
      end
      return nil
    end
    c = c:parent()
    hops = hops + 1
  end
end

-- Place the cursor on the symbol whose call hierarchy we want:
--   * cursor on a call            → the *called* function (callee name)
--   * cursor in/on an anon lambda → its variable, if assigned (f = func …)
--   * otherwise                   → the enclosing named definition (body/kw/…)
-- so the request works wherever the cursor sits, not just on a bare name.
local function place_cursor_on_symbol()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return end

  local callee = callee_at_cursor(node)
  if callee then
    goto_node_end(callee)
    return
  end

  while node do
    if FUNC_LIKE[node:type()] then
      local name = node:field("name")[1]
      if name then
        local row, col = name:start()
        pcall(vim.api.nvim_win_set_cursor, 0, { row + 1, col })
        return
      end
      -- anonymous: use the variable it's assigned to, else climb to the enclosing named fn
      local lhs = assigned_lhs(node)
      if lhs then
        goto_node_end(lhs)
        return
      end
    end
    node = node:parent()
  end
end

-- Smart incoming-calls: resolve the target symbol first, fire the request
-- (params are built synchronously from the cursor), then restore the cursor.
function M.incoming_calls()
  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  place_cursor_on_symbol()
  vim.lsp.buf.incoming_calls()
  pcall(vim.api.nvim_win_set_cursor, win, pos)
end

local lib_ok, lib = pcall(require, "litee.lib")
if not lib_ok then
  require("user.utils").info("skipped litee")
  return M
end

lib.setup({
  panel = { orientation = "left", panel_size = 40 },
  tree = { icon_set = "codicons" },
})

-- Calltree keymaps (in the tree buffer):
--   <CR> jump · zo/zc expand/collapse · zM collapse all · S switch incoming↔outgoing
--   i hover · d details · f focus · ? help · <Esc> close pop-out · q close
--   <leader>s{h,l,k,j} jump in a directional split · <leader>sv vsplit · <leader>st tab
--     (mirrors the global <leader>s… scheme in keymap.lua; s/v/t are unmapped)
-- litee's calltree.setup wraps its callHierarchy handlers in vim.lsp.with(fn, {}),
-- which Neovim 0.12 deprecated (and which is a no-op here — the opts are empty).
-- Stub vim.lsp.with with an identity wrapper across the setup call so the
-- "vim.lsp.with() is deprecated" warning never fires, then restore it. Behaviour
-- is unchanged: the only opts litee passes are {}.
local _orig_lsp_with = vim.lsp.with
vim.lsp.with = function(handler) return handler end
require("litee.calltree").setup({
  on_open = "popout", -- open the calltree as a floating popup window
  icon_set = "codicons",
  keymaps = { close = "q" }, -- q closes the tree (was X); <Esc> still closes the pop-out
  -- Don't let litee drag the source window around: its auto-highlight
  -- (litee.lib.highlights.auto) force-moves the invoking window's cursor to the
  -- node's definition line and highlights range.start..range.end on a single
  -- line — which mis-highlights multi-line ranges (e.g. gopls returns a symbol's
  -- full range) and yanks the cursor into the imports. We jump explicitly via <CR>.
  auto_highlight = false,
})
vim.lsp.with = _orig_lsp_with

-- Splits in the calltree buffer follow the same <leader>s + h/j/k/l/v/t scheme as
-- everywhere else (keymap.lua). litee runs a bare :split/:vsplit internally and
-- picks the side from 'splitbelow'/'splitright', so we force those around the jump
-- (and restore them after) — the same trick telescope.lua uses for its splits.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "calltree",
  callback = function(ev)
    local buf = ev.buf
    -- litee sets its own keymaps after FileType fires, so defer ours to win.
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then return end
      local o = { buffer = buf, silent = true, noremap = true }

      local function jump(cmd, opt, value)
        return function()
          local prev = vim.o[opt]
          vim.o[opt] = value
          vim.cmd(cmd)
          vim.schedule(function() vim.o[opt] = prev end)
        end
      end

      vim.keymap.set("n", "<leader>sh", jump("LTJumpCalltreeVSplit", "splitright", false), o) -- left
      vim.keymap.set("n", "<leader>sl", jump("LTJumpCalltreeVSplit", "splitright", true), o)  -- right
      vim.keymap.set("n", "<leader>sk", jump("LTJumpCalltreeSplit", "splitbelow", false), o)  -- up
      vim.keymap.set("n", "<leader>sj", jump("LTJumpCalltreeSplit", "splitbelow", true), o)   -- down
      vim.keymap.set("n", "<leader>sv", "<cmd>LTJumpCalltreeVSplit<cr>", o)                   -- vsplit
      vim.keymap.set("n", "<leader>st", "<cmd>LTJumpCalltreeTab<cr>", o)                      -- tab

      -- drop litee's single-key splits in favour of the <leader>s… scheme
      for _, k in ipairs({ "s", "v", "t" }) do
        pcall(vim.keymap.del, "n", k, { buffer = buf })
      end
    end)
  end,
})

return M
