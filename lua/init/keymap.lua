local nmap = require('user.utils').nnoremap
-- See `:help vim.keymap.set()`
-- vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
--vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
--vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
--vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
--vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-------------------------------------------------------------------------------
nmap("<leader>q", "<cmd>q<cr>", "󰅘 Quit (q)")
nmap("<leader>Q", "<cmd>bd<cr>", " Close buffer (:bd)")
nmap("<leader>w", "<cmd>w<cr>", " Save (:w)")
nmap("<leader>W", "<cmd>wa<cr>", " Save all (:wa)")
nmap("<leader>fc", "<cmd>nohlsearch<cr>", "No highlight search results")
-- vim.keymap.set("n", "<leader>n", "<cmd>ene!<cr>", {desc="New file"})
nmap("zo", "za", " Toggle fold under cursor")

-- Split
-- vim.keymap.set("n", "<leader>v", "<cmd>vsplit<cr>", {desc="Split Vertically"})
-- vim.keymap.set("n", "<leader>h", "<cmd>split<cr>", {desc="Split Horizontally"})

-- Buffers
--vim.keymap.set("n", "<C-l>", "<cmd>bnext<cr>")
--vim.keymap.set("n", "<C-h>", "<cmd>bprev<cr>")
-- nmap("<M-Right>", "<cmd>vertical resize +1<cr>", "Horizontally Resize +1")
-- nmap("<M-Left>", "<cmd>vertical resize -1<cr>", "Horizontally Resize -1")
-- nmap("<M-Up>", "<cmd>resize +1<cr>", "Vertical Resize +1")
-- nmap("<M-Down>", "<cmd>resize -1<cr>", "Vertical Resize -1")
-- TODO keymap tab movement
nmap("<M-l>", "<cmd>vertical resize +1<cr>", "󰡎 Horizontally Resize +1")
nmap("<M-h>", "<cmd>vertical resize -1<cr>", "󰡌 Horizontally Resize -1")
nmap("<M-k>", "<cmd>resize +1<cr>", "󰡏 Vertical Resize +1")
nmap("<M-j>", "<cmd>resize -1<cr>", "󰡍 Vertical Resize -1")

-- Better window movement
-- vim.keymap.set("n", "<C-h>", "<C-w>h")
-- vim.keymap.set("n", "<C-j>", "<C-w>j")
-- vim.keymap.set("n", "<C-k>", "<C-w>k")
-- vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Terminal mappings
vim.api.nvim_set_keymap('t', '<ESC>', [[<C-\><C-n>]], { noremap = true })

-- Netrw  mappings
-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1
--vim.keymap.set("n", "<leader>e", "<cmd>Ex<cr>", {desc="Explorer"})
--local netrw_mappings_group = vim.api.nvim_create_augroup("NetrwMappings", {})
--vim.api.nvim_create_autocmd("filetype", {
--  group = netrw_mappings_group,
--  pattern = "netrw",
--  desc = "Mappings for netrw",
--  callback = function()
--    local opts = { noremap = true, buffer = true }
--    vim.keymap.set("n", "v", "<cmd>normal! v<cr>", opts)
--  end,
--})
