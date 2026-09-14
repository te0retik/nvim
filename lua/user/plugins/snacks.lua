local ok, snacks = pcall(require, "snacks")
if not ok then
  require("user.utils").info("skipped snacks")
  return
end

-- Migration target from dressing.nvim:
--   input  → snacks.input  (replaces vim.ui.input)
--   select → snacks.picker (replaces vim.ui.select via Snacks.picker.select)
-- Everything else (statuscolumn, ...) stays off so the migration is
-- scope-equivalent to what dressing did.
snacks.setup({
  dashboard = {
    -- Start screen shown when nvim opens with no file. The "Restore Session"
    -- button (section = "session") is auto-wired to persistence.nvim.
    enabled = true,
    preset = {
      keys = {
        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
        { icon = " ", key = "f", desc = "Find File",     action = ":Telescope find_files" },
        { icon = " ", key = "g", desc = "Find Text",      action = ":Telescope live_grep" },
        { icon = " ", key = "r", desc = "Recent Files",   action = ":Telescope oldfiles" },
        { icon = " ", key = "v", desc = "Git Files",      action = ":Telescope git_files" },
        {
          icon = " ",
          key = "c",
          desc = "Config",
          action = function()
            require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
          end,
        },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      -- current directory name (function → re-evaluated each time the
      -- dashboard opens, so it always reflects the real cwd)
      function()
        return {
          align = "center",
          padding = 1,
          text = { { "󰉋 " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), hl = "Directory" } },
        }
      end,
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },
    },
  },
  input = {
    enabled = true,
    win = { style = "input", border = "rounded" },
  },
  picker = {
    enabled = true,
    ui_select = true, -- hook vim.ui.select
    layout = { preset = "select" },
  },
  words = {
    enabled = false,   -- handled by vim-illuminate instead (lsp -> treesitter -> regex fallback)
  },
  scroll = {
    enabled = true,    -- replaces neoscroll.nvim; smooth scrolling for <C-d>/<C-u>/<C-f>/<C-b>/zz/zt/zb
  },
  indent = {
    enabled = true,    -- replaces indent-blankline.nvim; indent guides
  },
  notifier = {
    enabled = true,    -- replaces lsp-progress.nvim; LSP progress + vim.notify as transient floats
    timeout = 3000,
    style = "compact",
  },
})

-- ── Terminals (zsh via $SHELL) ───────────────────────────────────────────
-- Snacks.terminal renders through Snacks.win, so the position is just a
-- win option. `toggle` keeps one persistent terminal per position; the tab
-- variant uses `open` (each tab wants its own) + position "current" so it
-- takes over the fresh tab's window instead of splitting it.
vim.keymap.set("n", "<leader>tt", function()
  Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 0.3 } })
end, { desc = " Terminal (bottom split)" })

vim.keymap.set("n", "<leader>tv", function()
  Snacks.terminal.toggle(nil, { win = { position = "right", width = 0.4 } })
end, { desc = " Terminal (right split)" })

vim.keymap.set("n", "<leader>tT", function()
  vim.cmd.tabnew()
  Snacks.terminal.open(nil, { win = { position = "current" } })
end, { desc = " Terminal (new tab)" })

-- In terminal mode every key goes to the shell, so <C-w> never reaches Neovim's
-- window commands. Scoped to snacks terminals only (filetype snacks_terminal, so
-- lazygit / other TUIs are untouched): make <C-w> drop to normal mode with the
-- window command still pending, so the whole <C-w>hjkl / <C-w>s / ... vocabulary
-- works straight from the terminal. Trade-off: zsh loses <C-w> (delete-word)
-- inside these buffers — use <C-u> or Alt+Backspace instead. (snacks also binds
-- a double <Esc> to reach normal mode if you prefer that.)
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_snacks_terminal_nav", { clear = true }),
  pattern = "snacks_terminal",
  callback = function(ev)
    vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]],
      { buffer = ev.buf, desc = "Window command (leave terminal)" })
  end,
})
