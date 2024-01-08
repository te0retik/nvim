function _G.custom_fold_text()
  local line = vim.fn.getline(vim.v.foldstart)

  local line_count = vim.v.foldend - vim.v.foldstart + 1

  return " ⚡ " .. line .. ": " .. line_count .. " lines"
end

function _G._fold_text_2()
  local line_first = vim.fn.getline(vim.v.foldstart)
  -- line_first = vim.fn.trim(line_first, "", 2)

  local ws = ""
  local ws_re = string.gmatch(line_first, "%s+")
  for ws_ in ws_re do
    ws = ws_
    break
  end

  line_first = vim.fn.trim(line_first)

  if string.len(line_first) < 40 and (vim.v.foldstart - vim.v.foldend <= 2) then
    local line_second = vim.fn.getline(vim.v.foldstart + 1)
    line_second = vim.fn.trim(line_second)
    line_first = line_first .. "  " .. line_second
  end

  local line_last = vim.fn.getline(vim.v.foldend)
  line_last = vim.fn.trim(line_last)

  -- ⚡    󰉸
  return string.format(
    [[%s%s ⋯ %s   %d  ]],
    ws, line_first, line_last,
    vim.v.foldend - vim.v.foldstart + 1
  )
end

vim.wo.foldtext = 'v:lua._fold_text_2()'
vim.wo.foldlevel = 3
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
vim.wo.fillchars = "fold: "
