local ok, zen_mode = pcall(require, "zen-mode")
if not ok then
  require('user.utils').info('skipped zen-mode')
	return
end

zen_mode.setup({
  window = {
    width = 140,
    options = { },
  },
})

vim.keymap.set("n", "<leader>z", zen_mode.toggle, {desc="Zen mode"})
