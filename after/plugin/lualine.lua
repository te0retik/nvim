local ok, lualine = pcall(require, "lualine")
if not ok then
  require('user.utils').info('skipped lualine')
	return
end

local lsp_progress_block = ''
local ok, lsp_progress = pcall(require, "lsp-progress")
if ok then
  lsp_progress_block = "require('lsp-progress').progress()"
end

lualine.setup({
  options = {
    icons_enabled = true,
    theme = 'onedark', -- auto
    -- component_separators = '|',
    component_separators = ' ',
    section_separators = '',
  },
  sections = {
    lualine_a = { { "mode", fmt = function(str) return str:sub(1, 1) end } },
    lualine_b = { "branch" },
    lualine_c = {
      {"filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      {"filename", file_status = false, path = 1},
      {"fileformat"},
      {"encoding"},
    },
    lualine_x = {
      {
        "diagnostics",
        sections = { "error", "warn" },
        symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H' },
        colored = true,           -- Displays diagnostics status in color if set to true.
        update_in_insert = false, -- Update diagnostics in insert mode.
        always_visible = false,   -- Show diagnostics even if there are none.
      },
      {
        "diff",
        --symbols = {
        --  added = icons.git.added,
        --  modified = icons.git.modified,
        --  removed = icons.git.removed,
        --},
        source = function()
          local gitsigns = vim.b.gitsigns_status_dict
          if gitsigns then
            return {
              added = gitsigns.added,
              modified = gitsigns.changed,
              removed = gitsigns.removed,
            }
          end
        end,
      },
    },
    lualine_y = {
      {
        function() return "  " .. require("dap").status() end,
        cond = function () return package.loaded["dap"] and require("dap").status() ~= "" end,
        --color = Util.ui.fg("Debug"),
      },
      { lsp_progress_block },
      {
        require("lazy.status").updates,
        cond = require("lazy.status").has_updates,
        --color = Util.ui.fg("Special"),
      },
      { "progress", separator = " ", padding = { left = 1, right = 0 } },
      { "location", padding = { left = 0, right = 1 } },
    },
    lualine_z = {
      function()
        return " " .. os.date("%R")
      end,
    }
  }
})

-- Refresh on progress
vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = "lualine_augroup",
  pattern = "LspProgressStatusUpdated",
  callback = require("lualine").refresh,
})
