local wk = require('which-key')
wk.setup()

-------------------------------------------------------------------------------
--  ["<C-n>"] = { "Go to mark 1" },
--  ["<C-m>"] = { "Go to mark 2" },
--  ["<C-t>"] = { "Go to terminal" },
--
wk.register({
  g = {
    name = "+Git",
    --    y = { "Yank URL" },
    --    s = { "Stage Hunk" },
    --    r = { "Reset Hunk" },
  },
}, { mode = "v", prefix = "<leader>" })

wk.register({
  -- c = {
  -- "Code Action"
  -- },
  t = {
    "+Tools"
  },
  g = {
    "+Git"
    --    y = { "Yank URL" },
    --    g = { "Stage Hunk" },
    --    r = { "Reset Hunk" },
    --    u = { "Undo Stage Hunk" },
    --    b = { "Toggle Line Blame" },
    --    d = { "Diff" },
    --    D = { "Diff ~" },
    --    p = { "Preview Hunk" },
    --    S = { "Stage Buffer" },
    --    R = { "Reset Buffer" },
  },
  l = {
    name = "+LSP",
    t = "+Diagnostic"
  },
  b = {
    "Buffer"
  },
  f = {
    "+Find"
  },
  ["."] = {
    "+Settings"
  },
  --  D = { "Databases" },
}, { mode = "n", prefix = "<leader>" })
