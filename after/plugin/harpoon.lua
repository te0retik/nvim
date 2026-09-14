local ok, _ = pcall(require, "harpoon")
if not ok then
  require('user.utils').info('skipped harpoon')
	return
end

local harpoon_mark = require("harpoon.mark")
local harpoon_ui = require("harpoon.ui")
local harpoon_term = require("harpoon.term")

vim.keymap.set("n", "<C-n>", function() harpoon_ui.nav_file(1) end)
vim.keymap.set("n", "<C-m>", function() harpoon_ui.nav_file(2) end)
vim.keymap.set("n", "<C-t>", function() harpoon_term.gotoTerminal(1) end)
vim.keymap.set("n", "<leader>m", harpoon_mark.add_file, {desc="Bookmark file"})
vim.keymap.set("n", "<leader>fb", function () harpoon_ui.toggle_quick_menu(); vim.cmd.norm("$ze"); end, {desc="Bookmarks"})
