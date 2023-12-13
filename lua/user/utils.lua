local utils = {}

function utils.nnoremap(lhs, rhs, desc)
  local opts = { noremap = true, remap = false, silent = true, desc = desc }
  vim.keymap.set('n', lhs, rhs, opts)
function utils.nnoremap(lhs, rhs, desc, opts)
  utils.noremap('n', lhs, rhs, desc, opts)
end

local opts_default = { noremap = true, remap = false, silent = true }

function utils.noremap(mode, lhs, rhs, desc, opts)
  local opts_ = vim.tbl_extend("force", opts_default, { desc = desc }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts_)
end

function utils.info(msg)
  -- vim.api.nvim_echo({{msg}}, false, {})
  -- print(msg)
end

return utils
