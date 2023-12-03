-- vim.cmd.colorscheme("onedark")
vim.cmd.colorscheme("tokyonight-night")

-- vim.cmd("colorscheme kanagawa-wave")
-- vim.cmd("colorscheme kanagawa-dragon")
-- vim.cmd("colorscheme kanagawa-lotus") or require("kanagawa").load("wave")
--

local catpuccin_ok, catpuccin = pcall(require, "catpuccin")
catpuccin_ok = false
if catpuccin_ok and false then
  catpuccin.setup({
    integrations = {
      aerial = true,
      alpha = true,
      cmp = true,
      dashboard = true,
      flash = true,
      gitsigns = true,
      headlines = true,
      illuminate = true,
      indent_blankline = { enabled = true },
      leap = true,
      lsp_trouble = true,
      mason = true,
      markdown = true,
      mini = true,
      native_lsp = {
        enabled = true,
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
      navic = { enabled = true, custom_bg = "lualine" },
      neotest = true,
      neotree = true,
      noice = true,
      notify = true,
      semantic_tokens = true,
      telescope = true,
      treesitter = true,
      treesitter_context = true,
      which_key = true,
    },

  })
end
