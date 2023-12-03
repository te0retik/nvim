local utils = {}

function utils.nnoremap(lhs, rhs, desc)
  local opts = { noremap = true, remap = false, silent = true, desc = desc }
  vim.keymap.set('n', lhs, rhs, opts)
end

function utils.info(msg)
  -- vim.api.nvim_echo({{msg}}, false, {})
  -- print(msg)
end

return utils
