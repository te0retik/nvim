local utils = {}

function utils.keymap(mode, lhs, rhs, desc)
  local opts = { noremap = true, silent = true, desc = desc }
  vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

function utils.info(msg)
  -- vim.api.nvim_echo({{msg}}, false, {})
  -- print(msg)
end

return utils
