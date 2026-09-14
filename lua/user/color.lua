local M = {}

function M.dump_highlights(filename)
  local function dumps_hlmap(hlmap)
    local function dumps_leaf(v)
      local t = type(v)
      if t == "string" then
        return '"' .. v .. '"'
      elseif t == "number" then
        local hex_color = string.format("%x", v)
        local m = 6 - string.len(hex_color)
        local zeros = string.rep("0", m)
        return '"#' .. zeros .. hex_color .. '"'
      elseif t == "boolean" then
        return tostring(v)
      else
        return '"' .. t .. "_unknown_" .. tostring(v) .. '"'
      end
    end

    local function dumps_table(tbl)
      local res
      local i = 0
      for k, v in pairs(tbl) do
        if i == 0 then
          res = '{'
        else
          res = res .. ', '
        end
        res = res .. k .. ' = ' .. dumps_leaf(v)
        i = i + 1
      end
      if res then
        res = res .. '}'
      end
      return res
    end

    local i = 0
    local dumped
    for k, v in pairs(hlmap) do
      if i == 0 then
        dumped = '{'
      else
        dumped = dumped .. ", "
      end
      if k == "blend" or k == "ctermfg" or k == "ctermbg" then
        dumped = dumped .. k .. " = " .. tostring(v)
      elseif k == "cterm" then
        local cterm_dumped = dumps_table(v)
        if cterm_dumped then
          dumped = dumped .. k .. " = " .. cterm_dumped
        end
      else
        dumped = dumped .. k .. ' = ' .. dumps_leaf(v)
      end
      i = i + 1
    end
    if dumped then
      dumped = dumped .. '}'
    end

    return dumped
  end

  local hl_groups_sorted = {}
  local hl = vim.api.nvim_get_hl(0, {})
  for n in pairs(hl) do table.insert(hl_groups_sorted, n) end
  table.sort(hl_groups_sorted)

  -- dump to table
  local file = io.open(filename, "w+")
  file:write("return {\n")
  for _, group in ipairs(hl_groups_sorted) do
    local params = hl[group]
    local hlparams_dumped = dumps_hlmap(params)
    if hlparams_dumped then
      local group_s = group
      if not string.match(group, "^[a-zA-Z]+[_a-zA-Z0-9]*$") then
        group_s = '["' .. group .. '"]'
      end
      local line = "  " .. group_s .. ' = ' .. hlparams_dumped .. ","
      file:write(line)
      file:write('\n')
    end
  end

  file:write("}")
  io.close(file)
end

function M.apply_highlights(highlights)
  for group, hlopts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, hlopts)
  end
end

return M
