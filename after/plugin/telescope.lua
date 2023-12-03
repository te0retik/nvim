local ok, telescope = pcall(require, "telescope")
if not ok then
  require('user.utils').info("skipped telescope")
  return
end

telescope.setup({
  pickers = {
    find_files = {
      -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
      find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*", "--glob", "!**/.py/*" },
    },
    buffers = {
      sort_lastused = true,
      ignore_current_buffer = false,
    }
  },
  defaults = {
    -- path_display = {"smart"},
    mappings = {
      n = {
        ["dd"] = "delete_buffer",
        ["<c-b>"] = "delete_buffer",
        -- ['<C-u>'] = false,
        -- ['<C-d>'] = false,
        -- ["<C-e>"] = function(bufnr) slow_scroll(bufnr, 1) end,
        -- ["<C-y>"] = function(bufnr) slow_scroll(bufnr, -1) end,
      },
      i = {
         ["<c-b>"] = "delete_buffer",
      },
    },
  },
})

-- If you want both scrolling speeds, it might be easier to write your own custom slow scrolling action. Something like this:
-- https://github.com/nvim-telescope/telescope.nvim/issues/2602
-- local state = require("telescope.state")
-- local action_state = require("telescope.actions.state")
--
-- local slow_scroll = function(prompt_bufnr, direction)
--   local previewer = action_state.get_current_picker(prompt_bufnr).previewer
--   local status = state.get_status(prompt_bufnr)
--
--   -- Check if we actually have a previewer and a preview window
--   if type(previewer) ~= "table" or previewer.scroll_fn == nil or status.preview_win == nil then
--     return
--   end
--
--     previewer:scroll_fn(1 * direction)
-- end

pcall(telescope.load_extension, 'fzf')
-- pcall(require('telescope').load_extension, 'gh')

-- See `:help telescope.builtin`
local t = require("telescope.builtin")

vim.keymap.set('n', '<leader>fb', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  t.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = "buffer" })

vim.keymap.set('n', "<leader><space>", t.buffers, { desc = 'buffers list' })
vim.keymap.set('n', "<leader>ff", t.find_files, { desc = 'Files' })
vim.keymap.set('n', "<leader>fv", t.git_files, { desc = 'Git files' })
vim.keymap.set('n', "<leader>fg", t.live_grep, { desc = 'grep' })
vim.keymap.set('n', "<leader>fw", t.grep_string, { desc = 'Word under cursor' })
vim.keymap.set('n', "<leader>fd", t.diagnostics, { desc = 'Diagnostics' })
vim.keymap.set('n', "<leader>fs", t.registers, { desc = 'registers' })
vim.keymap.set('i', "<C-r>", t.registers, { desc = 'registers' })
vim.keymap.set('n', "<leader>fr", t.resume, { desc = 'Resume search' })
vim.keymap.set('n', "<leader>fH", t.help_tags, { desc = 'help tags' })
vim.keymap.set('n', "<leader>fM", t.man_pages, { desc = 'man pages' })
vim.keymap.set('n', "<leader>fK", t.keymaps, { desc = 'keymaps' })
vim.keymap.set('n', "<leader>fo", t.oldfiles, { desc = 'Recently Opened Files' })
vim.keymap.set('n', "<leader>fC", t.commands, { desc = 'commands' })
vim.keymap.set('n', "<leader>fL", t.highlights, { desc = 'highlights' })

vim.keymap.set('n', "<leader>.c", function() t.colorscheme({ enable_preview = true }); end,
  { desc = "Colorscheme with preview" })
