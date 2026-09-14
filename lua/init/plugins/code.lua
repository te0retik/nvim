return {

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
      "nvim-treesitter/nvim-treesitter-context", -- still on master
    },
    config = function() require("user.plugins.treesitter") end,
  },
}
