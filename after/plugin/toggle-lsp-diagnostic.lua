local ok, tld = pcall(require, "toggle_lsp_diagnostics")
if not ok then
  require('user.utils').info("skipped toggle_lsp_diagnostics")
end

vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  signs = false,
  severity_sort = true,
  update_in_insert = true,
  float = {
    --    focusable = false,
    --  style = "minimal",
    border = "rounded",
    header = "",
    --  source = "always",
    --  prefix = "",
  },
})


tld.init(vim.diagnostic.config())

vim.keymap.set("n", "<leader>ltu", function() tld.toggle_underline() end, { desc = "Toggle Underline", noremap = true, remap = false  })
vim.keymap.set("n", "<leader>lts", function() tld.toggle_signs() end, { desc = "Toggle Signs", noremap = true, remap = false  })
vim.keymap.set("n", "<leader>ltt", function() tld.toggle_virtual_text() end, { desc = "Toggle Virtual Text", noremap = true, remap = false  })
vim.keymap.set("n", "<leader>lti", function() tld.toggle_update_in_insert() end, { desc = "Toggle Update in insert", noremap = true, remap = false  })
vim.keymap.set("n", "<leader>lta", function() tld.toggle_diagnostics() end, { desc = "Toggle All", noremap = true, remap = false  })
vim.keymap.set("n", "<leader>ltR", function() tld.turn_on_diagnostics_default() end, { desc = "Reset to default", noremap = true, remap = false  })
vim.keymap.set("n", "<leader>ltf", function() tld.turn_off_diagnostics() end, { desc = "Off", noremap = true, remap = false  })
vim.keymap.set("n", "<leader>ltn", function() tld.turn_on_diagnostics() end, { desc = "On", noremap = true, remap = false  })

-- function diagnostic_toggle(global)
--   local vars, bufnr, cmd
--   if global then
--     vars = vim.g
--     bufnr = nil
--   else
--     vars = vim.b
--     bufnr = 0
--   end
--   vars.diagnostics_disabled = not vars.diagnostics_disabled
--   if vars.diagnostics_disabled then
--     cmd = 'disable'
--     vim.api.nvim_echo({ { 'Disabling diagnostics…' } }, false, {})
--   else
--     cmd = 'enable'
--     vim.api.nvim_echo({ { 'Enabling diagnostics…' } }, false, {})
--   end
--   vim.schedule(function() vim.diagnostic[cmd](bufnr) end)
-- end
