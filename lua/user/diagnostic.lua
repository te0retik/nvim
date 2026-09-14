vim.diagnostic.config({
  virtual_text = true,
  underline = false,
  signs = false,
  severity_sort = true,
  update_in_insert = true,
  float = {
    border = "rounded",
    header = "",
  },
})

local defaults = vim.deepcopy(vim.diagnostic.config() or {})

local function flip(opt)
  return function()
    local cfg = vim.diagnostic.config() or {}
    vim.diagnostic.config({ [opt] = not cfg[opt] })
  end
end

local function badge(v) return v and "[ON ]" or "[off]" end
local function lbl(name, opt)
  return function() return badge((vim.diagnostic.config() or {})[opt]) .. " " .. name end
end

-- Diagnostic toggles live under a hidden `<leader>lo` group (NOT `<leader>l.`).
-- The sticky/loop menu opener `<leader>l.` (see which-key.lua) must be a LEAF with
-- an action; if these toggles were its children, which-key would re-run the opener
-- action instead of showing the group (self-trigger -> "Recursion detected"), so the
-- sticky menu would not work. The opener shows THIS group in loop mode; inside the
-- loop the trailing keys (u/s/t/i/a/R/f/n/e) are unchanged.
require("which-key").add({
  -- NOTE: do NOT mark this group `hidden = true`: which-key drops hidden groups
  -- (and their children) from the lookup tree, so `show({ keys = "<leader>lo" })`
  -- would fail with "No mappings found". It stays a normal (visible) group.
  { "<leader>lo", group = "󰒡 Diagnostics" },
  { "<leader>lou", flip("underline"),        desc = lbl("Underline",         "underline") },
  { "<leader>los", flip("signs"),            desc = lbl("Signs",             "signs") },
  { "<leader>lot", flip("virtual_text"),     desc = lbl("Virtual text",      "virtual_text") },
  { "<leader>loi", flip("update_in_insert"), desc = lbl("Update in insert",  "update_in_insert") },
  { "<leader>loa", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end,
    desc = function() return badge(vim.diagnostic.is_enabled()) .. " All diagnostics" end },
  { "<leader>loR", function() vim.diagnostic.config(vim.deepcopy(defaults)) end, desc = "Reset to default" },
  { "<leader>lof", function() vim.diagnostic.enable(false) end, desc = "Off" },
  { "<leader>lon", function() vim.diagnostic.enable(true) end,  desc = "On" },
})
