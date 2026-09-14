local utils = {}

function utils.nnoremap(lhs, rhs, desc, opts)
  utils.noremap('n', lhs, rhs, desc, opts)
end

local opts_default = { noremap = true, remap = false, silent = true }

function utils.noremap(mode, lhs, rhs, desc, opts)
  local opts_ = vim.tbl_extend("force", opts_default, { desc = desc }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts_)
end

-- LSP hover, meant to be bound to K. Decides at press time instead of at attach
-- time, so it stays correct while clients come and go, and never lets K fall
-- through to 'keywordprg' (in Go that means `hor term go doc ...`, which cannot
-- even show unexported symbols).
-- Do not pass vim.lsp.buf.hover to vim.keymap.set directly: Neovim deletes a
-- buffer-local K whose callback is exactly that function once the last client
-- detaches (see reset_defaults() in runtime/lua/vim/lsp/client.lua).
function utils.hover()
  if next(vim.lsp.get_clients({ bufnr = 0, method = "textDocument/hover" })) then
    vim.lsp.buf.hover()
  else
    vim.notify("no hover: no LSP client attached to this buffer", vim.log.levels.WARN)
  end
end

function utils.info(msg)
  -- vim.api.nvim_echo({{msg}}, false, {})
  -- print(msg)
end

local region_to_text = function(region)
  local text = ''
  local maxcol = vim.v.maxcol
  for line, cols in vim.spairs(region) do
    local endcol = cols[2] == maxcol and -1 or cols[2]
    local chunk = vim.api.nvim_buf_get_text(0, line, cols[1], line, endcol, {})[1]
    text = ('%s%s\n'):format(text, chunk)
  end
  return text
end

local getposs = function(pos1, pos2)
  local start__pos = vim.fn.getpos(pos1)
  local finish_pos = vim.fn.getpos(pos2)

  print("start_=" .. start__pos[2] .. ',' .. start__pos[3] .. ',' .. start__pos[4])
  print("finish=" .. finish_pos[2] .. ',' .. finish_pos[3] .. ',' .. finish_pos[4])

  local start_ = { start__pos[2] - 1, start__pos[3] - 1 + start__pos[4] }
  local finish = { finish_pos[2] - 1, finish_pos[3] - 1 + finish_pos[4] }

  if start_[1] > finish[1] or (start_[1] == finish[1] and start_[2] > finish[2]) then
    start_, finish = finish, start_
  end

  print(
    "start=" .. (start_[0] or "None") .. ',' .. (start_[1] or "None") ..
    "  end=" .. (finish[0] or "None") .. ',' .. (finish[1] or "None")
  )
  if start_[1] < 0 or start_[2] < 0 then
    return nil, nil
  end

  return start_, finish
end

function utils.get_selected_text()
  -- FIXME use https://github.com/neovim/neovim/pull/22635/files
  local start_, end_ = getposs("'<", "'>")
  print("start=" .. tostring(start_) .. " end=" .. tostring(end_))
  if not start_ or not end_ then
    return ""
  end

  local r = vim.region(0, start_, end_, vim.fn.visualmode(), true)
  print("region=" .. tostring(r))
  local t = region_to_text(r)
  print("t=" .. tostring(t))
  return t
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
