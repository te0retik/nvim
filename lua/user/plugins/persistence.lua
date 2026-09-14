local ok, persistence = pcall(require, "persistence")
if not ok then
  require("user.utils").info("skipped persistence")
  return
end

local nnoremap = require("user.utils").nnoremap

-- What goes into the session. persistence.nvim drives native :mksession, so this
-- is just the sessionoptions list. Set explicitly (not only via opts.options) so
-- behaviour is guaranteed regardless of the plugin version's defaults.
--   - no "blank": don't restore empty/scratch buffers
--   - no bare "options"/"globals": don't drag global option state across sessions
vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

persistence.setup({
  -- Close the nvim-tree sidebar before writing the session, otherwise it comes
  -- back as an empty/broken split on restore.
  pre_save = function()
    local tree_ok, tree = pcall(require, "nvim-tree.api")
    if tree_ok then tree.tree.close() end
  end,
})

-- Keymaps (in addition to the "Restore Session" button on the dashboard).
-- <leader>S = Session (see which-key.lua). <leader>q/<leader>s are already taken.
nnoremap("<leader>Sr", function() persistence.load() end, "󰆓 Restore session (cwd)")
nnoremap("<leader>Sl", function() persistence.load({ last = true }) end, "󰆓 Restore last session")
nnoremap("<leader>Sd", function() persistence.stop() end, "󰆓 Stop saving current session")

-- Quit the whole editor in one shot so the FULL window/tab/buffer layout is what
-- gets saved. Mashing <leader>q (:q) collapses the layout window-by-window, so by
-- the time nvim exits only a single window remains to persist. :qa quits all at
-- once; we also save explicitly first so the session is captured even if
-- persistence.stop() was called earlier this session. :qa still aborts on unsaved
-- changes (session is already saved by then) — save the files, then quit again.
nnoremap("<leader>Sq", function()
  persistence.save()
  -- :qa aborts with E37 (or E162) when a buffer is unsaved, and going through
  -- vim.cmd turns that into an E5108 Lua traceback pointing back at this file —
  -- four lines of noise that never say WHICH buffer is dirty. Catch it and list
  -- them instead. The session is already written by then, so all that is left is
  -- to save the files and press the key again.
  local ok, err = pcall(vim.cmd, "qa")
  if ok then return end

  local unsaved = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].modified and vim.bo[b].buflisted then
      local name = vim.api.nvim_buf_get_name(b)
      unsaved[#unsaved + 1] = "  " ..
        (name ~= "" and vim.fn.fnamemodify(name, ":~:.") or ("[No Name] (buffer " .. b .. ")"))
    end
  end

  if #unsaved > 0 then
    vim.notify(
      ("Session saved. Not quitting — %d unsaved buffer%s:\n%s\n\nSave with :wa, then <leader>Sq again.")
        :format(#unsaved, #unsaved > 1 and "s" or "", table.concat(unsaved, "\n")),
      vim.log.levels.WARN,
      { title = "Save session & quit" }
    )
  else
    -- Something else blocked the quit (a QuitPre autocmd, a running terminal job…):
    -- show the Vim error only, without the Lua traceback wrapped around it.
    vim.notify(
      "Session saved. Quit aborted: " .. (tostring(err):match("E%d+:[^\n]*") or tostring(err)),
      vim.log.levels.WARN,
      { title = "Save session & quit" }
    )
  end
end, "󰗼 Save session & quit all")
