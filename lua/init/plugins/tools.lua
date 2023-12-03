return {
  -- "akinsho/toggleterm.nvim",

  { -- http client
    "rest-nvim/rest.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    ft = "http",
    lazy = true,
  },

  { -- DB
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = "DBUIToggle",
    lazy = true,
  },
}
