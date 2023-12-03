local ok, blankline = pcall(require, "ibl")
if not ok then
  require('user.utils').info("skipped ibl (blankline)")
	return
end

blankline.setup({
	enabled = true,
})
