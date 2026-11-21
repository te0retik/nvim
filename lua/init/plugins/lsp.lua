return {
  { -- Autocompletion (blink.cmp — Rust-based, replaces nvim-cmp + all cmp-* sources)
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        config = function() require("luasnip.loaders.from_vscode").lazy_load() end,
      },
    },
    config = function() require("user.plugins.blink-cmp") end,
  },

  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "folke/lazydev.nvim",
    },
    config = function() require("user.plugins.lspconfig") end,
  },

  { -- LSP rename edited in place on the symbol itself (floating input over the
    -- word) with live preview of all substitutions. lazy=true: lazy.nvim loads
    -- it on the first require() from the <leader>lr mapping in lspconfig.lua.
    "saecki/live-rename.nvim",
    lazy = true,
    opts = {},
  },

  { -- Highlight the symbol under the cursor: lsp -> treesitter -> regex fallback
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function() require("user.plugins.illuminate") end,
  },

  { -- Call hierarchy as an expandable tree (incoming/outgoing calls), with jump.
    "ldelossa/litee-calltree.nvim",
    dependencies = { "ldelossa/litee.nvim" },
    -- Load early in a normal context: setup() overrides the LSP callHierarchy
    -- handlers and must run before <leader>lc fires. Loading lazily on the
    -- keypress runs setup() under textlock, which crashes litee's help-buffer
    -- creation (E565) and leaves on_open unset (tree opens as a split, not a popup).
    event = "VeryLazy",
    keys = {
      -- Smart incoming calls (resolves the enclosing function if the cursor is
      -- not on its name); press `S` in the popout to switch incoming↔outgoing.
      { "<leader>lc", function() require("user.plugins.litee").incoming_calls() end, desc = " Call hierarchy" },
    },
    config = function() require("user.plugins.litee") end,
  },
}
