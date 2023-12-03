
vim.g.mapleader = ' '       -- `:help mapleader`
vim.g.maplocalleader = ' '  --  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)

require("init.keymap")
require("init.plugin_manager")

-- Options
vim.o.breakindent = true                   -- Enable break indent
--vim.wo.signcolumn = 'yes'                  -- Keep signcolumn on by default
--vim.wo.number = true                       -- Make line numbers default
vim.wo.wrap = false                        -- display long lines as-is
vim.wo.linebreak  = false
vim.wo.list = false
vim.wo.foldenable = false
-- vim.wo.foldnestmax = 5
-- vim.wo.foldminlines = 15
vim.wo.foldlevel = 3
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
-- vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
-- vim.wo.fillchars = "fold: "
vim.wo.foldtext = [[substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'...'.trim(getline(v:foldend)) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)']]
vim.opt.updatetime = 250                     -- Decrease update time
vim.opt.timeoutlen = 500
vim.opt.clipboard = 'unnamedplus'            -- Sync clipboard between OS and Neovim. See `:help 'clipboard'`
vim.opt.completeopt = { "menuone", "noselect" } -- Set completeopt to have a better completion experience
vim.opt.mouse = ''                           -- disable mouse mode
vim.opt.ignorecase = true                    -- Case-insensitive searching UNLESS \C or capital in search
vim.opt.smartcase = true
vim.opt.termguicolors = true                 -- NOTE: You should make sure your terminal supports this
vim.opt.expandtab = true                   -- convert tabs to spaces
vim.opt.smartindent = true                 -- autoindenting when starting a new line
vim.opt.showmode = true                    -- show the active mode
vim.opt.pumheight = 10                     -- pop up menu height
vim.opt.showtabline = 0                    -- hide tabs
vim.opt.hlsearch = true                    -- highlight all matches
vim.opt.hidden = true                      -- to keep multiple buffers open
vim.opt.splitbelow = true                  -- force all horizontal splits to go below current window
vim.opt.splitright = true                  -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false                   -- creates a swapfile
vim.opt.title = true                       -- set the title of window to the value of the titlestring
vim.opt.titlestring = "%<%F%=%l/%L"
vim.opt.shiftwidth = 2                     -- the number of spaces inserted for each indentation
vim.opt.tabstop = 2                        -- insert 4 spaces for a tab
vim.opt.cursorline = false                 -- don't highlight the current line
vim.opt.number = true                      -- show line numbers
vim.opt.numberwidth = 2
vim.opt.relativenumber = true              -- use relative line numbers
vim.opt.spell = false                      -- it distracts
vim.opt.spelllang = "en"
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.list = true
vim.opt.listchars = "tab:» ,nbsp:·,trail:~" -- configure whitespace simbols
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undodir = vim.fn.stdpath "cache" .. "/undo"
vim.opt.undofile = true                      -- enable persistent undo
-- vim.o.signcolumn = "yes"                  -- always show the sign column

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
