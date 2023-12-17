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

pcall(telescope.load_extension, "fzf")
-- pcall(require('telescope').load_extension, 'gh')

-- See `:help telescope.builtin`
local t = require("telescope.builtin")

local colorscheme_fuzzy_find = function() t.colorscheme({ enable_preview = true }); end
local current_buffer_fuzzy_find = function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  t.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
    winblend = 10,
    previewer = true,
  })
end

local nmap = require("user.utils").nnoremap
nmap("<leader><space>", t.buffers, "󰕸 buffers list")
nmap('<leader>fb', current_buffer_fuzzy_find, "󰕸  buffer")
nmap("<leader>ff", t.find_files, " Files")
nmap("<leader>fv", t.git_files, "  Git files")
nmap("<leader>fg", t.live_grep, " grep")
nmap("<leader>fw", t.grep_string, "  Word under cursor")
nmap("<leader>fd", t.diagnostics, " Diagnostics")
nmap("<leader>fs", t.registers, "registers")
nmap("<leader>fr", t.resume, " Resume search")
nmap("<leader>fH", t.help_tags, "󰋖 help tags")
nmap("<leader>fM", t.man_pages, "󰾙 man pages")
nmap("<leader>fK", t.keymaps, "  keymaps")
nmap("<leader>fo", t.oldfiles, "Recently Opened Files")
nmap("<leader>fC", t.commands, " commands")
nmap("<leader>fL", t.highlights, "highlights")
nmap("<leader>.c", colorscheme_fuzzy_find, " Colorscheme with preview")

local map = require('user.utils').noremap
map("i", "<C-r>", t.registers, 'registers')

-- local utils = require('user.utils')
-- map('v', '<space>fb', function()
--   local text = utils.get_selected_text()
--   t.current_buffer_fuzzy_find({ default_text = text })
-- end, "Search selected text in current buffer")
--
-- map('v', '<space>fg', function()
--   local text = utils.selected_text()
--   t.live_grep({ default_text = text })
-- end, 'Grep selected text')
