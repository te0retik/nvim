
vim.g.mapleader = ' '       -- `:help mapleader`
vim.g.maplocalleader = ' '  --  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)

-- Silence the "client.supports_method is deprecated" spam: illuminate (on every
-- cursor move), litee and trouble still call the deprecated dot-form
-- client.supports_method(). The call still works in Neovim 0.12, so drop just that
-- one deprecation notice and let every other one through untouched.
do
  local _orig_deprecate = vim.deprecate
  vim.deprecate = function(name, ...)
    if name == "client.supports_method" then return end
    return _orig_deprecate(name, ...)
  end
end

require("init.keymap")
require("init.plugin_manager")

-- User modules (not tied to a specific plugin)
require("user.reload")   -- defines :ReloadConfig / _G.ReloadConfig()
require("user.diagnostic")
require("user.foldtext")
require("user.hover_definition")
require("user.bufpick")  -- <leader><space>: pick a buffer by letter

-- Filetype-specific user modules (lazy: only loaded when needed)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  group = vim.api.nvim_create_augroup("UserGoFt", { clear = true }),
  once = true,
  callback = function() require("user.go") end,
})

-- Options
vim.o.breakindent = true                   -- Enable break indent
--vim.wo.signcolumn = 'yes'                  -- Keep signcolumn on by default
--vim.wo.number = true                       -- Make line numbers default
vim.wo.wrap = false                        -- display long lines as-is
vim.opt.whichwrap:append("h,l,<,>,[,]")    -- h/l (and arrows) wrap to prev/next line at line edges
vim.wo.linebreak  = false
vim.wo.list = false
vim.wo.foldenable = true            -- folding active from the start (so the first `za` toggles only the fold under the cursor, no mass-collapse)
vim.opt.foldlevelstart = 5          -- on open, fold code nested deeper than 5 levels
-- vim.wo.foldnestmax = 5
-- vim.wo.foldminlines = 15
-- vim.wo.foldlevel = 3
-- vim.wo.foldmethod = "expr"
-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- vim.wo.fillchars = "fold: "
-- vim.wo.foldtext = [[substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'⋯'.trim(getline(v:foldend)) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)']]
vim.opt.updatetime = 250                     -- Decrease update time
vim.opt.timeoutlen = 500
vim.opt.clipboard = 'unnamedplus'            -- Sync clipboard between OS and Neovim. See `:help 'clipboard'`
vim.opt.completeopt = { "menuone", "noselect" } -- Set completeopt to have a better completion experience
vim.opt.mouse = ''                           -- disable mouse mode
vim.opt.ignorecase = true                    -- Case-insensitive searching UNLESS \C or capital in search
vim.opt.smartcase = true
vim.opt.termguicolors = true                 -- NOTE: You should make sure your terminal supports this
vim.opt.expandtab = false                   -- convert tabs to spaces
vim.opt.smartindent = true                 -- autoindenting when starting a new line
vim.opt.showmode = true                    -- show the active mode
vim.opt.pumheight = 10                     -- pop up menu height
vim.opt.showtabline = 1                    -- hide tabs
vim.opt.hlsearch = true                    -- highlight all matches
vim.opt.hidden = true                      -- to keep multiple buffers open
vim.opt.splitbelow = true                  -- force all horizontal splits to go below current window
vim.opt.splitright = true                  -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false                   -- creates a swapfile
vim.opt.title = true                       -- set the title of window to the value of the titlestring
vim.opt.titlestring = "%<%F%=%l/%L"
vim.opt.shiftwidth = 4                     -- the number of spaces inserted for each indentation
vim.opt.tabstop = 4                        -- insert 4 spaces for a tab
vim.opt.cursorline = true                  -- enable so CursorLineNr styles the current line number
vim.opt.cursorlineopt = "number"           -- highlight ONLY the number, not the whole line background
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
-- See `:help vim.hl.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
