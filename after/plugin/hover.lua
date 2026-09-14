local hover_ok, hover = pcall(require, "hover")
if hover_ok then
  hover.setup({
    init = function()
      -- Require providers
      require("hover.providers.lsp")
      -- require('hover.providers.gh')
      -- require('hover.providers.gh_user')
      -- require('hover.providers.jira')
      require('hover.providers.man')
      require('hover.providers.dictionary')
    end,
    preview_opts = {
      -- border = 'single'
      border = 'rounded'
    },
    title = false,
    -- Whether the contents of a currently open hover window should be moved
    -- to a :h preview-window when pressing the hover keymap.
    preview_window = true,
    -- mouse_providers = { 'LSP' },
    -- mouse_delay = 5000,
  })

  -- Setup keymaps
  -- vim.keymap.set("n", "K", require("hover").hover, { desc = "hover.nvim" })

  -- Mouse support
  -- vim.keymap.set('n', '<MouseMove>', require('hover').hover_mouse, { desc = "hover.nvim (mouse)" })
  -- vim.o.mousemoveevent = true
end
