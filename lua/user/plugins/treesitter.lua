local ok, nvim_treesitter = pcall(require, "nvim-treesitter")
if not ok then
  require('user.utils').info("skipped treesitter")
  return
end

nvim_treesitter.setup()

local parsers = {
  'c', 'cpp', 'go', 'lua', 'python', 'rust',
  'tsx', 'sql', 'http', 'javascript', 'typescript',
  'vimdoc', 'vim', 'bash', 'json', 'jsonnet', 'yaml', 'toml',
  'make', 'markdown', 'markdown_inline',
  'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore',
}

-- async; safe to call repeatedly — installs only what's missing
nvim_treesitter.install(parsers)

-- highlighting + folding for installed parsers
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if lang and pcall(vim.treesitter.start, ev.buf, lang) then
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo.foldmethod = "expr"
      vim.wo.foldlevel = 5     -- start with deeply nested code folded; `za` then toggles only the fold under the cursor
      vim.wo.foldminlines = 15 -- only auto-close folds with more than 15 lines
    end
  end,
})

-- incremental selection (was previously configured in old API)
vim.keymap.set("n", "<c-space>", function() vim.cmd("normal! v") end, { desc = "ts: init selection" })

-- textobjects: select / move
local sel_ok, ts_select = pcall(require, "nvim-treesitter-textobjects.select")
local move_ok, ts_move = pcall(require, "nvim-treesitter-textobjects.move")

if sel_ok then
  require("nvim-treesitter-textobjects").setup({ select = { lookahead = true } })
  for lhs, query in pairs({
    aa = "@parameter.outer", ia = "@parameter.inner",
    af = "@function.outer",  ["if"] = "@function.inner",
    ac = "@class.outer",     ic = "@class.inner",
  }) do
    vim.keymap.set({ "x", "o" }, lhs, function() ts_select.select_textobject(query, "textobjects") end,
      { desc = "ts: select " .. query })
  end
end

if move_ok then
  for lhs, query in pairs({
    ["]m"] = "@function.outer", ["]]"] = "@class.outer",
  }) do
    vim.keymap.set({ "n", "x", "o" }, lhs, function() ts_move.goto_next_start(query, "textobjects") end,
      { desc = "ts: next start " .. query })
  end
  for lhs, query in pairs({
    ["]M"] = "@function.outer", ["]["] = "@class.outer",
  }) do
    vim.keymap.set({ "n", "x", "o" }, lhs, function() ts_move.goto_next_end(query, "textobjects") end,
      { desc = "ts: next end " .. query })
  end
  for lhs, query in pairs({
    ["[m"] = "@function.outer", ["[["] = "@class.outer",
  }) do
    vim.keymap.set({ "n", "x", "o" }, lhs, function() ts_move.goto_previous_start(query, "textobjects") end,
      { desc = "ts: prev start " .. query })
  end
  for lhs, query in pairs({
    ["[M"] = "@function.outer", ["[]"] = "@class.outer",
  }) do
    vim.keymap.set({ "n", "x", "o" }, lhs, function() ts_move.goto_previous_end(query, "textobjects") end,
      { desc = "ts: prev end " .. query })
  end
end

-- treesitter-context still uses master branch API
local ctx_ok, context = pcall(require, "treesitter-context")
if ctx_ok then
  vim.keymap.set("n", "cc", context.go_to_context, { desc = "ts: go to context" })
end
