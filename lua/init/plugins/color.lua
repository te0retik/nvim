-------------------------- Color Theme ----------------------------
return {
  { "navarasu/onedark.nvim",         lazy = true,  priority = 1000, name = "onedark" },
  { "ellisonleao/gruvbox.nvim",      lazy = true,  priority = 1000, name = "gruvbox"  },
  { "rebelot/kanagawa.nvim",         lazy = true,  priority = 1000 },
  { "EdenEast/nightfox.nvim",        lazy = true,  priority = 1000 },
  { "sainnhe/everforest",            lazy = true,  priority = 1000 },

  { "bluz71/vim-moonfly-colors",     lazy = true,  priority = 1000, name = "moonfly" },
  { "rose-pine/neovim",              lazy = true,  priority = 1000, name = "rose-pine" },
  { "nordtheme/vim",                 lazy = true,  priority = 1000, name = "nord" },
  { "catppuccin/nvim",               lazy = true,  priority = 1000, name = "catppuccin" },
  { "bluz71/vim-nightfly-colors",    lazy = true,  priority = 1000, name = "nightfly" },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function() require("user.plugins.colorscheme") end,
  },

  { -- color picker (ten sliders at once: RGB+HSL+CMYK) + color highlighter.
    -- Config in user/plugins/ccc.lua. The file events are for the highlighter
    -- (auto_enable paints #hex / LSP documentColor values in opened buffers);
    -- <leader>.C (CursorLine color, colorscheme.lua) loads it via :CccPick.
    "uga-rosa/ccc.nvim",
    cmd = { "CccPick", "CccConvert", "CccHighlighterToggle" },
    event = { "BufReadPost", "BufNewFile" },
    config = function() require("user.plugins.ccc") end,
  },

  -- { "rainglow/vim",                  priority = 1000 }, -- only for GVim
  -- https://github.com/altercation/vim-colors-solarized
  -- https://github.com/tomasr/molokai
  -- https://github.com/chriskempson/base16-vim
  -- https://github.com/mcchrish/vim-no-color-collections
  -- https://github.com/nanotech/jellybeans.vim
}
