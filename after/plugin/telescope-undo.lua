local telescope_ok, telescope = pcall(require, "telescope")
if not telescope_ok then
  require('user.utils').info("skipped telescope-undo")
  return
end

local undo_ok, undo = pcall(require, "telescope-undo")
if not undo_ok then
  require('user.utils').info("skipped telescope-undo")
  return
end

telescope.setup({
  extensions = {
    undo = {
      side_by_side = true,
      -- layout_strategy = "vertical",
      -- layout_config = {
      --   preview_height = 0.8,
      -- },
      -- mappings = {
      --   i = {
      --     ["<cr>"] = require("telescope-undo.actions").yank_additions,
      --     ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
      --     ["<C-cr>"] = require("telescope-undo.actions").restore,
      --     -- alternative defaults, for users whose terminals do questionable things with modified <cr>
      --     ["<C-y>"] = require("telescope-undo.actions").yank_deletions,
      --     ["<C-r>"] = require("telescope-undo.actions").restore,
      --   },
      --   n = {
      --     ["y"] = require("telescope-undo.actions").yank_additions,
      --     ["Y"] = require("telescope-undo.actions").yank_deletions,
      --     ["u"] = require("telescope-undo.actions").restore,
      --   },
      -- },
    },
  },
})

telescope.load_extension("undo")

vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>", { desc = "Undo history" })
