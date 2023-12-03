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
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", {desc="Quit (q)"})
vim.keymap.set("n", "<leader>Q", "<cmd>bd<cr>", {desc="Close buffer (:bd)"})
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", {desc="Save (:w)"})
vim.keymap.set("n", "<leader>W", "<cmd>wa<cr>", {desc="Save all (:wa)"})
-- vim.keymap.set("n", "<leader>n", "<cmd>ene!<cr>", {desc="New file"})
vim.keymap.set("n", "<leader>fc", "<cmd>nohlsearch<cr>", {desc="No highlight search results"})

vim.keymap.set("n", "zo", "za", {desc="Toggle fold under cursor"})

-- Split
-- vim.keymap.set("n", "<leader>v", "<cmd>vsplit<cr>", {desc="Split Vertically"})
-- vim.keymap.set("n", "<leader>h", "<cmd>split<cr>", {desc="Split Horizontally"})

-- Buffers
--vim.keymap.set("n", "<C-l>", "<cmd>bnext<cr>")
--vim.keymap.set("n", "<C-h>", "<cmd>bprev<cr>")
-- vim.keymap.set("n", "<leader>b]", "<cmd>vertical resize +5<cr>", {desc="Vertical Sesize +5"})
-- vim.keymap.set("n", "<leader>b[", "<cmd>vertical resize -5<cr>", {desc="Vertical Sesize -5"})

-- Better window movement
-- vim.keymap.set("n", "<C-h>", "<C-w>h")
-- vim.keymap.set("n", "<C-j>", "<C-w>j")
-- vim.keymap.set("n", "<C-k>", "<C-w>k")
-- vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Terminal mappings
vim.api.nvim_set_keymap('t', '<ESC>', [[<C-\><C-n>]], { noremap = true })

-- Netrw  mappings
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
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
