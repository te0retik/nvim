
local status_ok, luasnip = pcall(require, "luasnip")
if not status_ok then
  require('user.utils').info("skipped luasnip")
  return
end

local status_ok, from_vscode = pcall(require, "luasnip.loaders.from_vscode")
if not status_ok then
  require('user.utils').info("skipped luasnip.loaders.from_vscode")
  return
end

from_vscode.lazy_load()
