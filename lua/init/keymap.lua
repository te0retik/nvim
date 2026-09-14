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
vim.keymap.set('n', 'p', '"0p', { desc = 'Paste without yank', noremap = true, remap = false, silent = true })
vim.keymap.set('v', 'p', '"0p', { desc = 'Paste without yank', noremap = true, remap = false, silent = true })
vim.keymap.set('n', "<leader>q", "<cmd>q<cr>", {desc="󰅘 Quit (q)"})
vim.keymap.set('n', "<leader>Q", "<cmd>bd<cr>", {desc=" Close buffer (:bd)"})
vim.keymap.set('n', "<leader>w", "<cmd>w<cr>", {desc=" Save (:w)"})
vim.keymap.set('n', "<leader>W", "<cmd>wa<cr>", {desc=" Save all (:wa)"})
vim.keymap.set('n', "<leader>fC", "<cmd>nohlsearch<cr>", {desc="No highlight search results"})

-- Copy the current file's path to the system clipboard.
vim.keymap.set('n', "<leader>yn", function() vim.fn.setreg("+", vim.fn.expand("%:t")) end, {desc="󰷊 Copy file name"})
vim.keymap.set('n', "<leader>yr", function() vim.fn.setreg("+", vim.fn.expand("%:.")) end, {desc="󰷊 Copy relative path"})
vim.keymap.set('n', "<leader>ya", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, {desc="󰷊 Copy absolute path"})

-- Toggle comment (native gc/gcc, Nvim 0.10+) — replaces the old Comment.nvim mapping.
vim.keymap.set('n', "<leader>c", "gcc", {desc="// Toggle comment", remap = true})
vim.keymap.set('x', "<leader>c", "gc",  {desc="// Toggle comment", remap = true})

-- <Esc> in normal mode:
--   1. if current window is floating (LSP hover, signature, diagnostic, etc.) — close it
--   2. close any other floating windows attached to current tab
--   3. if buffer is a transient/scratch type (help, qf, lazy, mason, lspinfo…) — :close
--   4. otherwise just clear hlsearch
-- (NvimTree has its own buffer-local <Esc> from on_attach — that wins by buffer-locality.)
local transient_ft = {
  help = true, qf = true, lspinfo = true, checkhealth = true,
  lazy = true, mason = true, ["null-ls-info"] = true,
  notify = true, fugitive = true, git = true,
  DiffviewFiles = true, DiffviewFileHistory = true,
}
vim.keymap.set('n', '<Esc>', function()
  local cur_win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(cur_win).relative ~= "" then
    pcall(vim.api.nvim_win_close, cur_win, false)
    return
  end
  local closed_any = false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      if pcall(vim.api.nvim_win_close, win, false) then closed_any = true end
    end
  end
  if closed_any then return end
  if transient_ft[vim.bo.filetype] then
    vim.cmd("close")
    return
  end
  vim.cmd("nohlsearch")
end, { desc = "Close floating/transient window or clear hlsearch" })
vim.keymap.set('n', "zo", "za", {desc=" Toggle fold under cursor"})
-- `l` opens the fold under the cursor when sitting on a closed fold, otherwise moves right
vim.keymap.set('n', "l", function()
  if vim.fn.foldclosed(vim.fn.line(".")) ~= -1 then
    return "zo"
  end
  return "l"
end, {expr = true, desc = "Move right / open fold under cursor"})
vim.keymap.set('n', "q", "", {desc=""})
-- vim.keymap.set("n", "<leader>n", "<cmd>ene!<cr>", {desc="New file"})

-- Tabs on Meta-keys — frees the vim built-ins t/T (find-til) and m (set-mark)
vim.keymap.set('n', "<M-n>", "<cmd>tabnext<cr>",  {desc="Next tab"})
vim.keymap.set('n', "<M-p>", "<cmd>tabprev<cr>",  {desc="Prev tab"})
vim.keymap.set('n', "<M-t>", "<cmd>tabnew<cr>",   {desc="New tab"})
vim.keymap.set('n', "<M-w>", "<cmd>tabclose<cr>", {desc="Close tab"})
vim.keymap.set('n', "<leader>r", "<cmd>tabnew<cr>", {desc="New tab"})
vim.keymap.set('n', "<leader>T", "<cmd>tabnew<cr>", {desc="New tab"})
-- Move the tab itself. <M-N>/<M-P> mirror <M-n>/<M-p>: same finger, Shift means
-- "carry the tab along instead of jumping to another one". <C-w>th/tl kept as the
-- window-command spelling.
-- :tabm +1 / -1 do not clamp at the ends, they fail with "E475: Invalid argument",
-- so wrap explicitly: past the last tab is the first, and vice versa.
local function tabmove(dir)
  return function()
    local cur, last = vim.fn.tabpagenr(), vim.fn.tabpagenr("$")
    if dir > 0 then
      vim.cmd(cur == last and "tabmove 0" or "tabmove +1")
    else
      vim.cmd(cur == 1 and "tabmove $" or "tabmove -1")
    end
  end
end
vim.keymap.set('n', "<M-P>",   tabmove(-1), {desc="Move tab left"})
vim.keymap.set('n', "<M-N>",   tabmove(1),  {desc="Move tab right"})
vim.keymap.set('n', "<C-w>th", tabmove(-1), {desc="Move tab left"})
vim.keymap.set('n', "<C-w>tl", tabmove(1),  {desc="Move tab right"})

vim.keymap.set('n', "<leader>.i", "<cmd>Inspect<cr>", {desc="Inspect (hl/ts under cursor)"})
vim.keymap.set('n', "<leader>.I", "<cmd>InspectTree<cr>", {desc="Inspect treesitter tree"})

-- Under the hidden `<leader>lo` diagnostics group so it shows inside the `<leader>l.`
-- sticky loop menu (see diagnostic.lua / which-key.lua); NOT `<leader>l.` which must
-- stay a leaf opener.
vim.keymap.set('n', "<leader>loe", function() vim.diagnostic.reset() end, {desc="Reset diagnostic"})

vim.keymap.set('n', "<leader>.k", function() require("user.cheatsheet").open() end, {desc="⌨ Keybindings cheatsheet"})

vim.keymap.set('n', "<leader>.r", "<cmd>ReloadConfig<cr>", {desc="Reload config (init.* + user.*)"})
-- Full restart (nvim 0.12+) with session round-trip: saves the persistence
-- session and files, restarts, and the new instance restores the session
-- (see :Restart in user/reload.lua). (Replaced the old ":so %" mapping.)
vim.keymap.set('n', "<leader>.R", "<cmd>Restart<cr>", {desc="Restart nvim (save+restore session)"})
vim.keymap.set('n', "<leader>.p", "<cmd>Lazy<cr>",   {desc="Plugins (Lazy)"})

--
-- Split the *current* file directionally, then use it as an independent window.
-- Orthogonal to goto: split first (<leader>s + hjkl), then run gd/gt/gr/... in the
-- new split — that keeps the original window untouched. Direction is forced with
-- leftabove/rightbelow so it ignores 'splitright'/'splitbelow' (same hjkl direction
-- language as the picker / nvim-tree / trouble open scheme). <C-w>hjkl stays as the
-- native window-navigation.
vim.keymap.set("n", "<leader>sh", "<cmd>leftabove vsplit<cr>",  {desc=" Split left (current file)"})
vim.keymap.set("n", "<leader>sl", "<cmd>rightbelow vsplit<cr>", {desc=" Split right (current file)"})
vim.keymap.set("n", "<leader>sk", "<cmd>leftabove split<cr>",   {desc=" Split up (current file)"})
vim.keymap.set("n", "<leader>sj", "<cmd>rightbelow split<cr>",  {desc=" Split down (current file)"})
vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<cr>",            {desc=" Vertical split (current file)"})
vim.keymap.set("n", "<leader>st", "<cmd>tab split<cr>",         {desc=" New tab (current file)"})

-- Buffers
--vim.keymap.set("n", "<C-l>", "<cmd>bnext<cr>")
--vim.keymap.set("n", "<C-h>", "<cmd>bprev<cr>")
-- vim.keymap.set('n', "<M-Right>", "<cmd>vertical resize +1<cr>", {desc="Horizontally Resize +1"})
-- vim.keymap.set('n', "<M-Left>", "<cmd>vertical resize -1<cr>", {desc="Horizontally Resize -1"})
-- vim.keymap.set('n', "<M-Up>", "<cmd>resize +1<cr>", {desc="Vertical Resize +1"})
-- vim.keymap.set('n', "<M-Down>", "<cmd>resize -1<cr>", {desc="Vertical Resize -1"})
vim.keymap.set('n', "<M-l>", "<cmd>vertical resize +1<cr>", {desc="󰡎 Horizontally Resize +1"})
vim.keymap.set('n', "<M-h>", "<cmd>vertical resize -1<cr>", {desc="󰡌 Horizontally Resize -1"})
vim.keymap.set('n', "<M-k>", "<cmd>resize +1<cr>", {desc="󰡏 Vertical Resize +1"})
vim.keymap.set('n', "<M-j>", "<cmd>resize -1<cr>", {desc="󰡍 Vertical Resize -1"})

-- editorconfig plugin used
-- vim.keymap.set('n', "<leader>.tt", function () vim.opt.expandtab = false end, {desc="vim.opt.expandtab = false"})
-- vim.keymap.set('n', "<leader>.tT", function () vim.opt.expandtab = true end, {desc="vim.opt.expandtab = true"})

-- vim.keymap.set('n', "<leader>.tl", function() vim.opt.showtabline = 0 end, {desc="vim.opt.showtabline = 0"})
-- vim.keymap.set('n', "<leader>.tL", function() vim.opt.showtabline = 1 end, {desc="vim.opt.showtabline = 1"})

-- Better window movement
-- vim.keymap.set("n", "<C-h>", "<C-w>h")
-- vim.keymap.set("n", "<C-j>", "<C-w>j")
-- vim.keymap.set("n", "<C-k>", "<C-w>k")
-- vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Terminal mappings.
-- <Esc> normally drops out of the terminal into normal mode. In lazygit, pass
-- <Esc> straight through instead so it acts as lazygit's own "back / cancel"
-- (return to the previous panel / close a popup) rather than killing lazygit.
-- Quit lazygit itself with `q`. Any other terminal: drop to normal mode.
vim.keymap.set('t', '<Esc>', function()
  if vim.api.nvim_buf_get_name(0):find("lazygit", 1, true) then
    return [[<Esc>]]
  end
  return [[<C-\><C-n>]]
end, { expr = true, noremap = true })

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
