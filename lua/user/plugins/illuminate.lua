local ok, illuminate = pcall(require, "illuminate")
if not ok then
  require("user.utils").info("skipped illuminate")
  return
end

illuminate.configure({
  -- Provider fallback chain: use the LSP (which distinguishes read/write) when a
  -- server is attached; otherwise fall back to treesitter, then a plain regex.
  -- This is what makes highlighting still work when the LSP env isn't set up.
  providers = { "lsp", "treesitter", "regex" },
  delay = 300,             -- ms after the cursor settles before highlighting
  large_file_cutoff = 2000,
  large_file_overrides = { -- in huge files, LSP only (skip treesitter/regex scans)
    providers = { "lsp" },
  },
  min_count_to_highlight = 1,
})

-- Single source of truth: link to the LspReference* groups, which are defined
-- (light) in lua/user/plugins/colorscheme.lua override(). This keeps illuminate
-- and the native LSP document-highlight consistent from one place. Read/write is
-- only distinguished by the LSP provider; the treesitter/regex fallback paints
-- every occurrence with IlluminatedWordText (the neutral group).
-- Re-applied on every ColorScheme: :colorscheme runs `hi clear`, which wipes
-- these links — themes with illuminate support redefine them, bare ones don't,
-- and the highlight silently disappears after a theme switch.
local function link_illuminate()
  vim.api.nvim_set_hl(0, "IlluminatedWordText",  { link = "LspReferenceText" })
  vim.api.nvim_set_hl(0, "IlluminatedWordRead",  { link = "LspReferenceRead" })
  vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })
end
link_illuminate()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_illuminate_hl", { clear = true }),
  callback = link_illuminate,
})

-- Navigation between references (parity with the previous mappings).
local function map(key, dir)
  vim.keymap.set("n", key, function()
    illuminate["goto_" .. dir .. "_reference"](false)
  end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " reference" })
end
map("]]", "next")
map("[[", "prev")
