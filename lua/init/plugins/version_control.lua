return {
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function() require("user.plugins.gitsigns") end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    lazy = true,
    -- Keymaps live here (not in user/plugins/diffview.lua): the plugin is
    -- cmd-lazy, so maps defined in its config would only exist after the first
    -- :Diffview* call. `keys` registers them (and which-key entries) upfront.
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Project history" },
    },
    config = function() require("user.plugins.diffview") end,
  },
  {
    "petertriho/cmp-git",
    dependencies = "nvim-lua/plenary.nvim",
    ft = { "gitcommit", "octo", "NeogitCommitMessage" },
  },
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- integrated diffs
    },
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit" },
    },
    config = function()
      require("neogit").setup({
        integrations = { diffview = true },
      })
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
      { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (file)" },
      { "<leader>gl", "<cmd>LazyGitFilterCurrentFile<cr>", desc = "LazyGit log (file)" },
    },
  },
}
