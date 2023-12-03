return {
  -- "kevinhwang91/nvim-ufo", -- collapse blocks
  -- "tpope/vim-surround"
  -- "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
  -- lewis6991/hover.nvim

  { "debugloop/telescope-undo.nvim" }, -- or { "mbbill/undotree" },

  { 'windwp/nvim-autopairs',                      event = "InsertEnter" },

  { "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim" },

  { "numToStr/Comment.nvim",                      lazy = true }, -- to comment visual regions/lines

  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-context", -- show breadcrumbs
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    build = ':TSUpdate',
  },
}
