
local ok, gitsigns = pcall(require, "gitsigns")
if not ok then
  require('user.utils').info('skipped gitsigns')
	return
end

-- vim.keymap.set('n', "<leader>P", gitsigns.setup, { desc = 'gitsigns.setup' })

gitsigns.setup({
  signs = {
  -- add = { text = '+' },
  -- change = { text = '~' },
  -- delete = { text = '_' },
  -- topdelete = { text = '‾' },
  -- changedelete = { text = '~' },
  },
  signcolumn = true,          -- Toggle with `:Gitsigns toggle_signs`
  numhl     = true,           -- Toggle with `:Gitsigns toggle_numhl`
  linehl    = false,          -- Toggle with `:Gitsigns toggle_linehl`
  current_line_blame = true,  -- Toggle with `:Gitsigns toggle_current_line_blame`
  --attach_to_untracked = true,
  watch_gitdir = {
    interval = 1000,
    follow_files = true
  },
  on_attach = function(bufnr)
    local map = function(keys, func, desc, mode)
      local mmode = 'n'
      if mode then
        mmode = mode
      end
      vim.keymap.set(mmode, keys, func, { buffer = bufnr, desc = desc, noremap = true, remap = false })
    end

    local gs = package.loaded.gitsigns

    map('<leader>gs', gs.stage_hunk, 'Stage hunk')
    map('<leader>gS', gs.stage_buffer, 'Stage buffer')
    map('<leader>gr', gs.reset_hunk, 'Reset hunk')
    map('<leader>gR', gs.reset_buffer, 'Reset buffer')
    map('<leader>gI', gs.reset_buffer_index, 'Reset buffer Index')
    map('<leader>gu', gs.undo_stage_hunk, 'Undo Stage hunk')
    map('<leader>gD', gs.diffthis, 'Diff')
    -- map('<leader>gD', function() gs.diffthis('~') end, 'Diff ~')
    map('<leader>gp', gs.preview_hunk, 'Preview git hunk')
    map('<leader>ge', gs.refresh, 'refresh')
    map('<leader>gb', gs.toggle_current_line_blame, 'Toggle current line Blame')
    map('<leader>gj', gs.toggle_deleted, "Toggle deleted")
    map('<leader>gl', gs.toggle_linehl, "Toggle linehl")
    map('<leader>gn', gs.toggle_numhl, "Toggle numhl")
    map('<leader>gw', gs.toggle_word_diff, "Toggle word diff")
    map('<leader>gi', gs.toggle_signs, "Toggle signs")
    -- map('q', function() vim.cmd("q") end, 'quit diff')
    --map('<leader>gq', gs.detach_all, 'detach')
    --map('<leader>gs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Stage hunk', 'v')
    --map('<leader>gr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Reset hunk', 'v')
    -- Text object
    map('ih', ':<C-U>Gitsigns select_hunk<CR>', 'Select Hunk', { 'o', 'x' })

    -- don't override the built-in and fugitive keymaps
    vim.keymap.set(
      { 'n', 'v' }, ']c',
      function()
        if vim.wo.diff then
          return ']c'
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end,
      { expr = true, buffer = bufnr, desc = 'Jump to next hunk' }
    )

    vim.keymap.set(
      { 'n', 'v' }, '[c',
      function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end,
      { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' }
    )
  end,
})
