return {
  {
    "folke/zen-mode.nvim",
    event = "VeryLazy",
    opts = { window = { width = 140, options = {} } },
    config = function(_, opts)
      require("zen-mode").setup(opts)
      require("which-key").add({
        {
          "<leader>z",
          function() require("zen-mode").toggle() end,
          desc = function()
            local on = require("zen-mode.view").is_open()
            return (on and "[ON ]" or "[off]") .. " Zen mode"
          end,
        },
      })
    end,
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function() require("user.plugins.snacks") end,
  },

  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    event = "VeryLazy",
    config = function()
      require("window-picker").setup({
        hint = "floating-big-letter",
        selection_chars = "FJDKSLA;CMRUEIWOQP",
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "NvimTree", "neo-tree", "notify", "noice" },
            buftype = { "terminal", "quickfix", "prompt" },
          },
        },
      })
      local function pick_and_jump()
        local win = require("window-picker").pick_window()
        if win then vim.api.nvim_set_current_win(win) end
      end
      vim.keymap.set("n", "<leader>ww", pick_and_jump, { desc = "󰖯 Pick window (jump cursor)" })
      vim.keymap.set("n", "<C-w><Space>", pick_and_jump, { desc = "󰖯 Pick window (jump cursor)" })
    end,
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("user.plugins.todo-comments") end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "antosha417/nvim-lsp-file-operations",
      { "b0o/nvim-tree-preview.lua", lazy = true, dependencies = { "nvim-lua/plenary.nvim" } },
    },
    config = function() require("user.plugins.nvim-tree") end,
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require("user.plugins.lualine") end,
  },

  {
    "stevearc/aerial.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    keys = {
      { "<leader>lt", "<cmd>AerialToggle!<cr>", desc = "󰙅 Symbol tree (aerial)" },
    },
    config = function()
      require("aerial").setup({
        backends = { "lsp", "treesitter", "markdown", "man" },
        layout = { default_direction = "right", min_width = 30 },
        show_guides = true,
        filter_kind = false, -- show all kinds (structs, methods, fields, …)
      })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    -- master (was '0.1.x' — stale, incompatible with nvim-treesitter `main`)
    dependencies = {
      "nvim-lua/plenary.nvim",
      "debugloop/telescope-undo.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function() return vim.fn.executable("make") == 1 end,
      },
    },
    config = function() require("user.plugins.telescope") end,
  },
}
