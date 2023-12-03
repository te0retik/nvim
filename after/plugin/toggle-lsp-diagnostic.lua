local ok, tld = pcall(require, "toggle_lsp_diagnostics")
if not ok then
  require('user.utils').info("skipped toggle_lsp_diagnostics")
end

vim.diagnostic.config({
  virtual_text = true,
  underline = false,
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

local nmap = require('user.utils').nnoremap
nmap("<leader>ltu", tld.toggle_underline, "Toggle Underline")
nmap("<leader>lts", tld.toggle_signs, "Toggle Signs")
nmap("<leader>ltt", tld.toggle_virtual_text, "Toggle Virtual Text")
nmap("<leader>lti", tld.toggle_update_in_insert, "Toggle Update in insert")
nmap("<leader>lta", tld.toggle_diagnostics, "Toggle All")
nmap("<leader>ltR", tld.turn_on_diagnostics_default, "Reset to default")
nmap("<leader>ltf", tld.turn_off_diagnostics, "Off")
nmap("<leader>ltn", tld.turn_on_diagnostics, "On")

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
