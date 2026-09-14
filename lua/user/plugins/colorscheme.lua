local function override()
  local none = "NONE"
  local colors = {
    none = none,
    keyword = "#C15A00",  -- #D26200 #CC7832 #BA6B26
    builtin = "#B21F46",
    comment = "#8c8c8c",  -- #6C6C6C #767676
    identifier = "#444444",
    property = "#0017AB", -- #41147C #41068E #0042A6
    call = "#5000b4",     --#4906a0 #00398F #215BB0
    string = "#3D7500",   --#4B741E
  }
  local highlights = {
    Function = { undercurl = true, bold = true },
    Comment = { fg = colors.comment },
    Type = { bold = true },
    String = { fg = colors.string },
    Statement = { fg = "#9854f1", bold = true },
    Visual = { undercurl = true, bg = "#d0f0d0" },               -- #BEDEBE #c6e7c6
    Search = { undercurl = true, fg = "black", bg = "#e2e4aa" }, -- #C3C8E2 #ccd1ec #d4daf5 #e1e6ff #e6eafe
    Special = { link = "Constant" },                             -- { fg = "green" },
    TabLineSel = { bg = "#e9edf4" },

    -- plugins
    ["@operator"] = { fg = "black" },
    ["@property"] = { fg = colors.property },
    ["@variable"] = { fg = colors.identifier },
    ["@variable.builtin"] = { fg = colors.builtin },
    ["@type.builtin"] = { fg = colors.builtin, bold = false },
    ["@keyword"] = { bold = true, undercurl = false, fg = colors.keyword },
    ["@keyword.function"] = { bold = true, undercurl = false, fg = colors.keyword },
    ["@method.call"] = { undercurl = false, fg = colors.call },
    ["@function.call"] = { undercurl = false, fg = colors.call, bold = false },
    ["@function.builtin"] = { fg = colors.builtin },
    ["@lsp.type.method.lua"] = { bold = false },
    ["@lsp.type.function.lua"] = { bold = false },
    ["@type.go"] = { bold = false },

    lualine_a_normal = { bg = "#a9cdff", fg = "gray" },

    TelescopeMatching = { --[[ undercurl = true,  ]] fg = "black", bg = "#E6E5E6" },
    TreesitterContext = { bg = "#dee2f7" },

    GitSignsAdd = { fg = "#009800" }, -- #399a96
    GitSignsChange = { fg = "#4478e0" },
    GitSignsDelete = { fg = "#d60000" },

    -- Single source of truth for symbol-occurrence highlighting. Both illuminate
    -- (IlluminatedWord*, linked in illuminate.lua) and the native LSP document
    -- highlight resolve to these. Light, low-contrast backgrounds so the syntax
    -- text on top stays fully legible.
    LspReferenceText = { bg = "#E4E6EE", underline = true },   -- neutral grey; also treesitter/regex fallback
    LspReferenceRead = { bg = "#DCE4FF", underline = true },   -- read access — light blue
    LspReferenceWrite = { bg = "#F6DEF2", underline = true },  -- write access — light pink

    -- Current line number: make it pop (needs cursorline=true, cursorlineopt has
    -- "number" — set in init.lua). Bold + strong accent + a light box behind it.
    CursorLineNr = { fg = "#C15A00", bg = "#FFE6C7", bold = true },

    TodoBgnote = { link = "TodoBgtodo" },
    TodoBgtodo = { bg = "#BCF6FE" },
    TodoBgwarn = { bg = "#FCE8A9", undercurl = true },
    TodoBgfix = { bg = "#FCA9D2", undercurl = true },
    TodoBgperf = { bg = "#E3A9FC" },
  }

  for k, v in pairs(highlights) do
    vim.api.nvim_set_hl(0, k, v)
  end
end

local function init_tokyonight()
  require("tokyonight").setup({
    style = "night",     -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
    light_style = "day", -- The theme is used when the background is set to light
    transparent = true,
    -- transparent = false,
    styles = {
      -- Background styles. Can be "dark", "transparent" or "normal"
      sidebars = "transparent", -- style for sidebars, see below
      floats = "transparent",   -- style for floating windows
    },
    -- on_highlights = function(hl, colors)
    -- end,
  })
  -- vim.cmd.colorscheme("tokyonight-night")
  vim.cmd.colorscheme("tokyonight-day")
end

local function init_rose_pine()
  require("rose-pine").setup({
    -- variant = "main",
    variant = "dawn",
    disable_background = true,
    disable_float_background = false,
    highlight_groups = {
      FloatTitle = { bg = "none" },
      FloatBorder = { bg = "none" },
      NormalFloat = { bg = "none" },
      TelescopeBorder = { fg = "highlight_high", bg = "none" },
      TelescopeNormal = { bg = "none" },
      TelescopePromptNormal = { bg = "base" },
      TelescopeResultsNormal = { fg = "subtle", bg = "none" },
      TelescopeSelection = { fg = "text", bg = "base" },
      TelescopeSelectionCaret = { fg = "rose", bg = "rose" },
      GitSignsAdd = { bg = "none" },
      GitSignsChange = { bg = "none" },
      GitSignsDelete = { bg = "none" },
    },
  })

  -- vim.cmd("colorscheme rose-pine")
  vim.cmd("colorscheme rose-pine")

  vim.diagnostic.config({ float = { border = "rounded" } })
end

local function init_kanagawa()
  require("kanagawa").setup({
    compile = false,  -- enable compiling the colorscheme
    undercurl = true, -- enable undercurls
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true, bold = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = true,    -- do not set background color
    dimInactive = false,   -- dim inactive window `:h hl-NormalNC`
    terminalColors = true, -- define vim.g.terminal_color_{0,17}
    colors = {             -- add/modify theme and palette colors
      palette = {},
      theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    overrides = function(colors) -- add/modify highlights
      return {}
    end,
    theme = "wave",  -- Load "wave" theme when 'background' option is not set
    background = {   -- map the value of 'background' option to a theme
      dark = "wave", -- try "dragon" !
      light = "lotus"
    },
  })
  vim.cmd.colorscheme("kanagawa")
end
-- vim.cmd("colorscheme kanagawa-wave")
-- vim.cmd("colorscheme kanagawa-dragon")
-- vim.cmd("colorscheme kanagawa-lotus") or require("kanagawa").load("wave")

local function init_catpuccin()
  local catpuccin_ok, catpuccin = pcall(require, "catpuccin")
  if catpuccin_ok and false then
    catpuccin.setup({
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        headlines = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    })
  end
end

-- ── Persist / restore the active colorscheme across sessions ──────────────
-- Remember the colorscheme + 'background' the user last settled on and restore
-- it on the next launch. Falls back to the configured default below if nothing
-- was saved yet or the saved scheme fails to load.
local state_file = vim.fn.stdpath("state") .. "/last_colorscheme"

local function save_colorscheme()
  local name = vim.g.colors_name
  if not name or name == "" then return end
  local fd = io.open(state_file, "w")
  if not fd then return end
  fd:write(vim.o.background .. "\n" .. name .. "\n")
  fd:close()
end

local function read_colorscheme()
  local fd = io.open(state_file, "r")
  if not fd then return nil end
  local bg, name = fd:read("*l"), fd:read("*l")
  fd:close()
  if not name or name == "" then return nil end
  return { background = bg, name = name }
end

local function apply_default()
  vim.o.background = "light"
  init_tokyonight() -- sets colorscheme "tokyonight-day"
  -- init_kanagawa()
  -- init_catpuccin()
  -- init_rose_pine()
  -- vim.cmd.colorscheme("miss-dracula")
  -- vim.cmd.colorscheme("onedark")
end

-- ── Keep the block cursor visible on every theme ─────────────────────────
-- Some schemes leave the `Cursor` highlight undefined or too close to their
-- background, so the block cursor blends in. Instead of hand-tuning a colour
-- per theme, invert `Normal`: the cursor block takes the theme's text colour
-- and the glyph takes its background — maximum contrast on both light and dark.
-- Themes here are transparent, so `Normal.bg` can be empty; fall back to a
-- sensible value based on 'background'.
local function fix_cursor()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local dark = vim.o.background == "dark"
  local block = normal.fg or (dark and 0xc8d3f5 or 0x343b58) -- glyph background
  local glyph = normal.bg or (dark and 0x1a1b26 or 0xe1e2e7) -- glyph itself
  vim.api.nvim_set_hl(0, "Cursor", { bg = block, fg = glyph })
  vim.api.nvim_set_hl(0, "lCursor", { bg = block, fg = glyph })
end

-- Subtle current-line highlight for every theme ('cursorlineopt' includes
-- "line", see init.lua). Theme CursorLine backgrounds are often loud; instead
-- derive our own: Normal bg nudged 7% toward Normal fg — just enough to track
-- the cursor without shouting, on light and dark schemes alike.
local function blend(a, b, t) -- 0xRRGGBB ints, t in [0,1]
  local function mix(shift)
    local ca = math.floor(a / shift) % 256
    local cb = math.floor(b / shift) % 256
    return math.floor(ca + (cb - ca) * t + 0.5) * shift
  end
  return mix(65536) + mix(256) + mix(1)
end

local cursorline_bg_file = vim.fn.stdpath("state") .. "/cursorline_bg"

local function fix_cursorline()
  -- a hand-picked color (<leader>.C below) wins over the derived blend
  local fd = io.open(cursorline_bg_file, "r")
  if fd then
    local hex = (fd:read("*l") or ""):gsub("%s+", "")
    fd:close()
    if hex:match("^#%x%x%x%x%x%x$") then
      vim.api.nvim_set_hl(0, "CursorLine", { bg = hex })
      return
    end
  end
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local dark = vim.o.background == "dark"
  local bg = normal.bg or (dark and 0x1a1b26 or 0xe1e2e7)
  local fg = normal.fg or (dark and 0xc8d3f5 or 0x343b58)
  vim.api.nvim_set_hl(0, "CursorLine", { bg = blend(bg, fg, 0.06) })
end

-- Pick the CursorLine background with ccc.nvim (custom input shows RGB+HSL+CMYK
-- sliders all at once — see user/plugins/ccc.lua). ccc edits color text in a
-- buffer, so a one-line scratch float holds the current hex; confirming the
-- pick (<CR> in ccc) rewrites that line, which applies + persists the color
-- and closes the float. q/<Esc> in the float cancels.
-- :CursorLineColorReset returns to the automatic blend.
vim.keymap.set("n", "<leader>.C", function()
  if vim.fn.exists(":CccPick") ~= 2 then
    vim.notify("ccc.nvim is not available", vim.log.levels.WARN)
    return
  end
  local cur = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).bg
  local hex = cur and string.format("#%06x", cur) or "#888888"
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { hex })
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor", row = 1, col = 0, width = #hex + 2, height = 1,
    border = "rounded", title = " CursorLine bg ", style = "minimal",
  })
  vim.api.nvim_win_set_cursor(win, { 1, 1 })
  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = function()
      local line = (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""):gsub("%s+", "")
      if line:match("^#%x%x%x%x%x%x$") and line ~= hex then
        local fd = io.open(cursorline_bg_file, "w")
        if fd then fd:write(line .. "\n"); fd:close() end
        fix_cursorline()
        vim.schedule(close)
      end
    end,
  })
  vim.schedule(function() vim.cmd("CccPick") end)
end, { desc = "CursorLine color (ccc sliders)" })

vim.api.nvim_create_user_command("CursorLineColorReset", function()
  os.remove(cursorline_bg_file)
  fix_cursorline()
  vim.notify("CursorLine: auto blend")
end, { desc = "drop the hand-picked CursorLine color" })

-- Bind the cursor shapes to the `Cursor`/`lCursor` highlight groups. Neovim only
-- emits the terminal cursor-colour escape (OSC 12) for a mode when its guicursor
-- entry names a highlight group; the default block entry (`n-v-c-sm:block`) names
-- none, so the terminal keeps drawing its own fixed cursor colour and fix_cursor()
-- has no visible effect. (In iTerm2 also disable Preferences ▸ Profiles ▸ Colors ▸
-- "Smart cursor color", which overrides the app-set colour.)
vim.o.guicursor = "n-v-c-sm:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,"
  .. "r-cr-o:hor20-Cursor/lCursor,t:block-blinkon500-blinkoff500-TermCursor"

-- Fires on every :colorscheme (startup restore, telescope picker, manual).
-- Re-applies our light-theme overrides for light schemes and persists the choice.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_colorscheme_persist", { clear = true }),
  callback = function()
    if vim.o.background == "light" then override() end
    fix_cursor()
    fix_cursorline() -- after override(), so the subtle bg wins over the dump's
    save_colorscheme()
  end,
})

local saved = read_colorscheme()
if saved then
  if saved.background == "light" or saved.background == "dark" then
    vim.o.background = saved.background
  end
  if not pcall(vim.cmd.colorscheme, saved.name) then
    apply_default()
  end
else
  apply_default()
end

vim.api.nvim_create_user_command(
  "DumpHighlights",
  function(opts)
    local filename = "lua/user/highlights.lua"
    if opts.args ~= "" then
      filename = opts.args
    end
    require("user.color").dump_highlights(filename)
  end,
  { nargs = '?' }
)

vim.api.nvim_create_user_command(
  "ImportHighlights",
  function(opts)
    local filename = "lua.user.highlights"
    if opts.args ~= "" then
      filename = opts.args
    end
    local hl = require(filename)
    require("user.color").apply_highlights(hl)
  end,
  { nargs = '?' }
)
