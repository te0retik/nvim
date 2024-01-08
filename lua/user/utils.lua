local utils = {}

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

function utils.table_to_string(tbl)
  if not tbl then
    return '<empty>'
  end
  local result = "{"
  for k, v in pairs(tbl) do
    -- Check the key type (ignore any numerical keys - assume its an array)
    if type(k) == "string" then
      result = result .. k .. "="
    end

    -- Check the value type
    if type(v) == "table" then
      result = result .. utils.table_to_string(v)
    elseif type(v) == "boolean" then
      result = result .. tostring(v)
    else
      result = result .. '"' .. v .. '"'
    end
    result = result .. ","
  end
  -- Remove leading commas from the result
  if result ~= "" then
    result = result:sub(1, result:len() - 1)
  end

  return result .. "}"
end

return utils
