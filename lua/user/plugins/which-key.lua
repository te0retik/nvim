local wk = require('which-key')
wk.setup({
  -- Glyphs are curated by hand in each keymap's `desc` (and via the `icon` field
  -- for the fold group below). which-key's rule-based icons would add a SECOND,
  -- redundant glyph: when a mapping has no icon of its own it inherits its parent
  -- group's rule-matched icon (e.g. <leader>fl "Location list" showed the Find
  -- group's magnifier on top of its own map-marker). `rules = false` disables
  -- only that rule/inherited layer; explicit `icon` fields still render, so the
  -- fold icons below are unaffected.
  icons = { rules = false },

  -- Align labels. Our glyphs are curated by hand *inside* each `desc` (see the
  -- note above), not in which-key's `icon` field, so which-key can't pad its
  -- (empty) icon column for entries that have no glyph — those stick to the far
  -- left while glyph-prefixed neighbours sit one glyph+space to the right.
  -- `replace.desc` runs a chain of rules over every label; the trailing function
  -- indents the icon-less ones so their text lines up. NOTE: this list overrides
  -- which-key's defaults wholesale (tbl_deep_extend merges lists by index), so
  -- the 8 built-in cleanups are re-listed verbatim before our rule.
  replace = {
    desc = {
      { "<Plug>%(?(.*)%)?", "%1" },
      { "^%+", "" },
      { "<[cC]md>", "" },
      { "<[cC][rR]>", "" },
      { "<[sS]ilent>", "" },
      { "^lua%s+", "" },
      { "^call%s+", "" },
      { "^:%s*", "" },
      -- Indent labels that don't already start with a glyph. A leading Nerd Font
      -- glyph lives in the Private Use Area (>= U+E000); a leading space means the
      -- glyph is in the `icon` field (e.g. the fold group) — leave both alone.
      -- Everything else is plain text: prefix a glyph-width + space of padding.
      function(desc)
        local cp = vim.fn.strgetchar(desc, 0) -- first codepoint, -1 if empty
        if cp >= 0 and cp ~= 0x20 and cp < 0xE000 then
          return "  " .. desc
        end
        return desc
      end,
    },
  },
})

wk.add({
  { "<leader>g", group = "+  Git", mode = "v" },

  { "<leader>d", group = "+  Debug" },
  { "<leader>i", group = "+ 󰚩 AI / Claude" },
  { "<leader>t", group = "+ Tools" },
  { "<leader>g", group = "+  Git" },
  { "<leader>l", group = "+ LSP" },
  -- Sticky Diagnostic menu: which-key stays open in a loop after each toggle
  -- (flip several at once), exit with <Esc>. The toggles live in a HIDDEN
  -- `<leader>lo` group (diagnostic.lua / keymap.lua); this leaf just opens that
  -- group in loop mode. It MUST show a different node than itself: `<leader>l.`
  -- carries this action, so if the toggles were its own children which-key would
  -- re-run this action instead of showing them (self-trigger -> "Recursion
  -- detected") and the sticky menu would never open.
  {
    "<leader>l.",
    function() require("which-key").show({ keys = "<leader>lo", loop = true }) end,
    desc = "󰒡 Diagnostics (sticky menu)",
  },
  { "<leader>f", group = "+ Find" },
  { "<leader>f", group = "+ Find", mode = "v" }, -- visual-mode leaf: <leader>fs greps the selection
  { "<leader>s", group = "+ Split (current file)" },
  { "<leader>S", group = "+ 󰆓 Session" },
  { "<leader>y", group = "+ 󰆏 Yank path" },
  { "<leader>.", group = "+ Settings" },

  -- Спрятать встроенный пошаговый resize окна из <C-w> попапа (сами команды работают)
  { "<C-w><", hidden = true },
  { "<C-w>>", hidden = true },
  { "<C-w>-", hidden = true },
  { "<C-w>+", hidden = true },


  -- Folds (all under the `z` prefix; descriptions cluster them in the popup)
  -- NOTE: leading space in each label is the gap after the icon (which-key strips trailing ws, keeps leading)
  -- Icon system: double-chevron = all levels, single-chevron = one level, circled-chevron = fold under cursor; down = open, up = close
  { "z", group = " Fold / View", icon = "" },
  { "zR", desc = " Open all folds", icon = "" },
  { "zM", desc = " Close all folds", icon = "" },
  { "zr", desc = " Open one fold level (all)", icon = "" },
  { "zm", desc = " Close one fold level (all)", icon = "" },
  { "zo", desc = " Open fold under cursor", icon = "" },
  { "zc", desc = " Close fold under cursor", icon = "" },
  { "za", desc = " Toggle fold under cursor", icon = "" },
  { "zA", desc = " Toggle folds recursively", icon = "" },
  { "zf", desc = " Create fold (motion)", icon = "" },
  { "zF", desc = " Create fold (N lines)", icon = "" },
  { "zv", desc = " View cursor line (open folds)", icon = "" },
  { "zx", desc = " Update folds (reapply foldlevel)", icon = "" },
  { "zd", desc = " Delete fold under cursor", icon = "" },
  { "zD", desc = " Delete folds recursively", icon = "" },
  { "zE", desc = " Delete (eliminate) all folds", icon = "" },
  -- View: position the cursor line on screen
  { "zt", desc = " Top this line", icon = "" },
  { "zz", desc = " Center this line", icon = "" },
  { "zb", desc = " Bottom this line", icon = "" },
  { "zs", desc = " Left this line", icon = "" },
  { "ze", desc = " Right this line", icon = "" },
  { "zH", desc = " Half screen to the left", icon = "" },
  { "zL", desc = " Half screen to the right", icon = "" },
})

vim.keymap.set("n", "<leader>.w", "<cmd>:checkhealth which-key<cr>", { desc = "which-key health" })
