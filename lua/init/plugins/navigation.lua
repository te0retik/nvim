------------------------------- NAVIGATION ----------------------------------
return {
  { "folke/zen-mode.nvim",    event = "VeryLazy" },
  -- "preservim/tagbar",
  -- "akinsho/bufferline.nvim",
  -- "nacro90/numb.nvim", -- Peeking the buffer while entering command :{number}
  -- "alexghergh/nvim-tmux-navigation",
  -- "phaazon/hop.nvim" or ggandor/lightspeed.nvim or folke/flash.nvim
  -- "stevearc/aerial.nvim", -- A code outline window for skimming and quick navigation

  -- workspaces
  -- "natecraddock/workspaces.nvim",
  -- "rmagatti/auto-session/tree/main",

  { "stevearc/dressing.nvim", event = "VeryLazy" },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  { "karb94/neoscroll.nvim" },
  -- {"ggandor/lightspeed.nvim", event = "BufRead"},
  -- {
  --   "folke/trouble.nvim",
  --   dependencies = "nvim-tree/nvim-web-devicons",
  -- },
  --{
  --  "theprimeagen/harpoon",
  --  dependencies = "nvim-lua/plenary.nvim",
  --},
  {               -- Add indentation guides even on blank lines
    "lukas-reineke/indent-blankline.nvim",
    main = 'ibl', -- See `:help ibl`
  },
  --{ -- edit FS like buffer
  --  'stevearc/oil.nvim',
  --  dependencies = { "nvim-tree/nvim-web-devicons" },
  --}
  {
    -- file explorer
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "antosha417/nvim-lsp-file-operations",
      { "JMarkin/nvim-tree.lua-float-preview", lazy = true },
    },
    --config = function()
    --  require("nvim-tree").setup {}
    --end,
  },
  {                              -- Set lualine as statusline
    "nvim-lualine/lualine.nvim", -- See `:help lualine.txt`
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "linrongbin16/lsp-progress.nvim",
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    branch = '0.1.x',
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },

  -- {
  -- -- file explorer
  -- "nvim-neo-tree/neo-tree.nvim",
  -- branch = "v2.x"
  -- dependencies = {
  --   "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons",
  --   "MunifTanjim/nui.nvim", "s1n7ax/nvim-window-picker",
  -- }
  --{
  --    "s1n7ax/nvim-window-picker",
  --    name = 'window-picker',
  --    event = 'VeryLazy',
  --    version = '2.*',
  --    config = function()
  --        require'window-picker'.setup()
  --    end,
  --},
}
-------------------------------------------------------------------------------
