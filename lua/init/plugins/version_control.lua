return {
  ---------------------------- version control ----------------------
  -- "tpope/vim-fugitive",
  -- "tpope/vim-rhubarb",

  {                            -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim", -- See `:help gitsigns.txt`
    event = "VeryLazy",
  },

  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    lazy = true,
  },

  { "petertriho/cmp-git", requires = "nvim-lua/plenary.nvim" },

  --{
  --  "ruifm/gitlinker.nvim",
  --  dependencies = "nvim-lua/plenary.nvim",
  --  event = "BufRead",
  --},
  -------------------------------------------------------------------
}
