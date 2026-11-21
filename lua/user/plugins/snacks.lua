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
    --
    -- Two-pane layout (each pane `width` cols, `pane_gap` between):
    --   pane 1 (left):  header, cwd + branch, buttons, startup stats
    --   pane 2 (right): recent files in cwd, git status, open PRs / issues
    -- Needs ~2*width + pane_gap = 124 columns; on a narrower terminal snacks
    -- stacks the panes into a single column automatically.
    enabled = true,
    width = 60,
    pane_gap = 4,
    preset = {
      keys = {
        { icon = "󰁯 ", key = "s", desc = "Restore Session", section = "session" },
        { icon = "󰆓 ", key = "S", desc = "Select Session",  action = function() require("persistence").select() end },
        { icon = "󰈞 ", key = "f", desc = "Find File",     action = ":Telescope find_files" },
        { icon = " ", key = "g", desc = "Find Text",      action = ":Telescope live_grep" },
        { icon = "󰋚 ", key = "r", desc = "Recent Files",   action = ":Telescope oldfiles" },
        { icon = "󰊢 ", key = "v", desc = "Git Files",      action = ":Telescope git_files" },
        { icon = " ", key = "n", desc = "New File",       action = ":ene | startinsert" },
        { icon = " ", key = "l", desc = "LazyGit",        action = ":LazyGit" },
        { icon = " ", key = "t", desc = "TODOs",          action = ":TodoTelescope" },
        { icon = "󰒲 ", key = "u", desc = "Update Plugins", action = ":Lazy update" },
        {
          icon = " ",
          key = "c",
          desc = "Config",
          action = function()
            require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
          end,
        },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      -- ── pane 1 (left) ──────────────────────────────────────────────────
      { section = "header" },
      -- cwd name + git branch (function → re-evaluated each time the
      -- dashboard opens, so it always reflects the real cwd / HEAD)
      function()
        local text = { { "󰉋 " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), hl = "Directory" } }
        if Snacks.git.get_root() then
          local branch = vim.fn.systemlist("git branch --show-current")[1]
          if branch == nil or branch == "" then -- detached HEAD → short sha
            branch = vim.fn.systemlist("git rev-parse --short HEAD")[1] or "?"
          end
          text[#text + 1] = { "   " .. branch, hl = "special" }
        end
        return { align = "center", padding = 1, text = text }
      end,
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },

      -- ── pane 2 (right) ─────────────────────────────────────────────────
      -- Last 5 files opened under the current cwd; <1>..<5> open them.
      { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", cwd = true, limit = 5, indent = 2, padding = 1 },

      -- Git status, bounded: first 8 entries from `git status --porcelain`,
      -- then a "+N more" line and staged/modified/untracked totals computed
      -- over the full list, so a repo with 500 dirty files still fits in
      -- 10 rows. Plain function section (not `terminal`), so there is no
      -- cache, no "[Process exited 0]" tail, and the branch line is not
      -- repeated (it is already shown in pane 1). Colours follow git:
      -- index column green, worktree / untracked column red.
      {
        pane = 2,
        icon = " ",
        title = "Git Status",
        indent = 2,
        padding = 1,
        enabled = function() return Snacks.git.get_root() ~= nil end,
        function()
          local max = 8
          local entries = vim.fn.systemlist("git status --porcelain --renames")
          if vim.v.shell_error ~= 0 then
            return { { text = { { "git status failed", hl = "Comment" } } } }
          end
          if #entries == 0 then
            return { { text = { { "clean", hl = "Added" } } } }
          end
          local items, staged, modified, untracked = {}, 0, 0, 0
          for i, line in ipairs(entries) do
            local x, y, path = line:sub(1, 1), line:sub(2, 2), line:sub(4)
            if x == "?" then
              untracked = untracked + 1
            else
              if x ~= " " then staged = staged + 1 end
              if y ~= " " then modified = modified + 1 end
            end
            if i <= max then
              items[#items + 1] = { text = {
                { x, hl = x ~= " " and x ~= "?" and "Added" or "Removed" },
                { y, hl = "Removed" },
                { " " .. path },
              } }
            end
          end
          if #entries > max then
            items[#items + 1] = { text = { { ("… +%d more"):format(#entries - max), hl = "Comment" } } }
          end
          items[#items + 1] = { text = { {
            ("%d staged · %d modified · %d untracked"):format(staged, modified, untracked),
            hl = "Comment",
          } } }
          return items
        end,
      },

      -- Open PRs (5) as a table + issues (3) via `gh`. Cached for 5 min (ttl)
      -- since it hits the network; falls back to a one-liner when gh can't
      -- answer (non-GitHub remote, not logged in, offline).
      --
      -- The PR table comes from scripts/dashboard-prs.sh (one GraphQL call,
      -- formatted with jq): `#  title  author  cmts  unres  CI`, my PRs first.
      -- cmts = all comments, unres = unresolved review threads, CI = rollup of
      -- the last commit's checks with the failed check names on the lines
      -- below. Args: <limit> <width|auto> <max failed names per PR>; `auto`
      -- reads the pty width snacks gives the section (`width - indent`), so rows
      -- stretch to the pane and never wrap.
      {
        pane = 2,
        icon = " ",
        title = "Pull Requests / Issues",
        section = "terminal",
        enabled = function() return vim.fn.executable("gh") == 1 and Snacks.git.get_root() ~= nil end,
        --
        -- The whole output is padded with blank lines up to the pty height
        -- (= `height`): termopen appends "[Process exited 0]" to the terminal
        -- buffer when the job ends and snacks does not strip it, so it only
        -- stays hidden when it lands below the visible window.
        -- (`rows` is read before the pipeline: inside it stdin is the pipe,
        -- not the pty, and `stty size` would fail.)
        cmd = ("rows=$(stty size 2>/dev/null | cut -d' ' -f1); { %s; } | awk -v rows=\"$rows\" '{ print } END { for (i = NR; i < rows; i++) print \"\" }'"):format(table.concat({
          "echo 'PRs:'",
          ("bash %s 5 auto 2"):format(vim.fn.shellescape(vim.fn.stdpath("config") .. "/scripts/dashboard-prs.sh")),
          "echo 'Issues:'",
          -- stderr is captured so "issues disabled" (a repo setting) is told
          -- apart from a real gh failure (offline / not logged in).
          [[out=$(gh issue list --limit 3 --json number,title,author --template '{{if .}}{{range .}}  #{{.number}} {{truncate 40 .title}} ({{.author.login}}){{"\n"}}{{end}}{{else}}  none{{"\n"}}{{end}}' 2>&1) && printf '%s\n' "$out" || case "$out" in *"disabled issues"*) echo "  issues disabled in this repo";; *) echo "  gh: unavailable";; esac]],
        }, "; ")),
        height = 14,
        indent = 2,
        padding = 1,
        ttl = 5 * 60,
      },
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
  image = {
    -- Inline images for markdown (and other docs): ![alt](path) is rendered
    -- right in the buffer via the kitty graphics protocol. Needs a terminal
    -- that speaks it (kitty, ghostty, wezterm) — in iTerm2 the module stays
    -- silent and nothing is drawn. Non-PNG formats additionally need
    -- ImageMagick (`brew install imagemagick`).
    enabled = true,
    doc = {
      enabled = true,
      inline = true,   -- draw in place of the ![..](..) line
      float = true,    -- fall back to a float when the window is too narrow
      max_width = 80,
      max_height = 40,
    },
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
