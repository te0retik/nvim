return {
  {
    "mfussenegger/nvim-dap",
    config = function() require("user.plugins.dap") end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = "mfussenegger/nvim-dap",
    config = function() require("user.plugins.dap-ui") end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {},
  },
  {
    "leoluz/nvim-dap-go",
    config = function() require("dap-go").setup() end,
  },
}
