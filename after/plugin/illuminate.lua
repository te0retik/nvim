local status_ok, illuminate = pcall(require, "illuminate")
if not status_ok then
  require('user.utils').info("skipped illuminate")
  return
end

illuminate.configure({
  delay = 300,
  large_file_cutoff = 2000,
  large_file_overrides = {
    providers = { "lsp" },
  },
})

local function map(key, dir, buffer)
  vim.keymap.set("n", key, function()
    illuminate["goto_" .. dir .. "_reference"](false)
  end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
end

map("]]", "next")
map("[[", "prev")

-- also set it after loading ftplugins, since a lot overwrite [[ and ]]
--vim.api.nvim_create_autocmd("FileType", {
--  callback = function()
--    local buffer = vim.api.nvim_get_current_buf()
--    map("]]", "next", buffer)
--    map("[[", "prev", buffer)
--  end,
--})
