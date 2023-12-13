local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system { -- `:help lazy.nvim.txt` for more info
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    "--depth=1",
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("init.plugins")

-- For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
