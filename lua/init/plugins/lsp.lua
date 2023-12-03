return {
  -- ray-x/lsp_signature.nvim
  -- {
  --  "VonHeikemen/lsp-zero.nvim",
  --  branch = "v2.x",
  --  dependencies = {
  --    -- LSP Support
  --    "neovim/nvim-lspconfig",             -- Required
  --    "williamboman/mason.nvim",           -- Optional
  --    "williamboman/mason-lspconfig.nvim", -- Optional
  --
  --    -- Autocompletion
  --    "hrsh7th/nvim-cmp",             -- Required
  --    "hrsh7th/cmp-nvim-lsp",         -- Required
  --    "L3MON4D3/LuaSnip",             -- Required
  --    "rafamadriz/friendly-snippets", -- Optional LuaSnip dependency
  --    "saadparwaiz1/cmp_luasnip",     -- Optional LuaSnip source
  --  }
  --},
  { "RRethy/vim-illuminate" }, -- highlight word under cursor
  {
    "linrongbin16/lsp-progress.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
  },
  -- "hrsh7th/cmp-cmdline",
  -- "hrsh7th/cmp-buffer",
  { -- Autocompletion
    "hrsh7th/nvim-cmp",
    dependencies = {
      "onsails/lspkind.nvim",
      -- Snippet Engine & its associated nvim-cmp source
      "L3MON4D3/LuaSnip",

      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "ray-x/cmp-treesitter",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
  },
  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { "j-hui/fidget.nvim", tag = 'legacy', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      "folke/neodev.nvim",
    },
  },
}
