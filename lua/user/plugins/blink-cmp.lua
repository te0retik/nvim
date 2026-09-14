local ok, blink = pcall(require, "blink.cmp")
if not ok then
  require("user.utils").info("skipped blink.cmp")
  return
end

blink.setup({
  -- default preset: <CR> accept, <Tab>/<S-Tab> nav+snippet, <C-Space> show, <C-y> accept,
  --                 <C-n>/<C-p> nav, <C-e> hide, <C-k> signature help
  keymap = {
    preset = "default",
    ["<C-d>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<CR>"]  = { "accept", "fallback" },
    -- Home-row navigation: Alt+j/Alt+k (same letters as vim down/up).
    -- C-n/C-p stay too. M-j/M-k are bound to resize in normal mode but
    -- the completion popup is insert-mode only, so no conflict here.
    ["<M-j>"] = { "select_next", "fallback" },
    ["<M-k>"] = { "select_prev", "fallback" },
  },

  appearance = { nerd_font_variant = "mono" },

  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    menu = { border = "rounded" },
    list = { selection = { preselect = true, auto_insert = false } },
  },

  signature = { enabled = true, window = { border = "rounded" } },

  snippets = { preset = "luasnip" },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    per_filetype = {
      sql = { "buffer" }, -- vim-dadbod-completion is nvim-cmp-only; buffer is best fallback
      gitcommit = { "git", "buffer" },
      NeogitCommitMessage = { "git", "buffer" },
    },
    providers = {
      git = { name = "git", module = "cmp_git.blink" },
    },
  },

  cmdline = {
    keymap = { preset = "cmdline" },
    completion = { menu = { auto_show = true } },
  },

  fuzzy = { implementation = "prefer_rust_with_warning" },
})
