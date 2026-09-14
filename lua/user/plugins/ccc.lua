local ok, ccc = pcall(require, "ccc")
if not ok then
  require("user.utils").info("skipped ccc")
  return
end

-- ── Combined input: RGB + HSL + CMYK, ten sliders at once ────────────────────
-- Straight from the ccc.nvim wiki ("Use multiple color spaces simultaneously"):
-- a custom ColorInput whose callback keeps all three models in sync — move an
-- HSL bar and the RGB/CMYK bars follow, and vice versa.
local ColorInput = require("ccc.input")
local convert = require("ccc.utils.convert")

local RgbHslCmykInput = setmetatable({
  name = "RGB/HSL/CMYK",
  max = { 1, 1, 1, 360, 1, 1, 1, 1, 1, 1 },
  min = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  delta = { 1 / 255, 1 / 255, 1 / 255, 1, 0.01, 0.01, 0.005, 0.005, 0.005, 0.005 },
  bar_name = { "R", "G", "B", "H", "S", "L", "C", "M", "Y", "K" },
}, { __index = ColorInput })

function RgbHslCmykInput.format(n, i)
  if i <= 3 then
    n = n * 255 -- RGB
  elseif i == 5 or i == 6 then
    n = n * 100 -- S/L of HSL
  elseif i >= 7 then
    return ("%5.1f%%"):format(math.floor(n * 200) / 2) -- CMYK
  end
  return ("%6d"):format(n)
end

function RgbHslCmykInput.from_rgb(RGB)
  local HSL = convert.rgb2hsl(RGB)
  local CMYK = convert.rgb2cmyk(RGB)
  local R, G, B = unpack(RGB)
  local H, S, L = unpack(HSL)
  local C, M, Y, K = unpack(CMYK)
  return { R, G, B, H, S, L, C, M, Y, K }
end

function RgbHslCmykInput.to_rgb(value)
  return { value[1], value[2], value[3] }
end

function RgbHslCmykInput:_set_rgb(RGB)
  self.value[1], self.value[2], self.value[3] = RGB[1], RGB[2], RGB[3]
end

function RgbHslCmykInput:_set_hsl(HSL)
  self.value[4], self.value[5], self.value[6] = HSL[1], HSL[2], HSL[3]
end

function RgbHslCmykInput:_set_cmyk(CMYK)
  self.value[7], self.value[8], self.value[9], self.value[10] =
      CMYK[1], CMYK[2], CMYK[3], CMYK[4]
end

function RgbHslCmykInput:callback(index, new_value)
  self.value[index] = new_value
  local v = self.value
  if index <= 3 then
    local RGB = { v[1], v[2], v[3] }
    self:_set_hsl(convert.rgb2hsl(RGB))
    self:_set_cmyk(convert.rgb2cmyk(RGB))
  elseif index <= 6 then
    local RGB = convert.hsl2rgb({ v[4], v[5], v[6] })
    self:_set_rgb(RGB)
    self:_set_cmyk(convert.rgb2cmyk(RGB))
  else
    local RGB = convert.cmyk2rgb({ v[7], v[8], v[9], v[10] })
    self:_set_rgb(RGB)
    self:_set_hsl(convert.rgb2hsl(RGB))
  end
end

ccc.setup({
  bar_len = 60, -- wide sliders (default 30)
  win_opts = { border = "rounded" },
  inputs = {
    RgbHslCmykInput,   -- all ten sliders at once
    ccc.input.okhsl,   -- `i` switches here: perceptually uniform lighter/darker
  },
  -- output formats, cycled with `o`; keep hex first (CursorLine picker parses it)
  outputs = {
    ccc.output.hex,
    ccc.output.hex_short,
    ccc.output.css_rgb,
    ccc.output.css_hsl,
    ccc.output.css_oklch,
  },
  -- Paint color literals in code with their actual color. lsp = true prefers
  -- textDocument/documentColor from the attached server (css/tailwind etc.)
  -- and falls back to the built-in picker-based highlighter elsewhere.
  highlighter = {
    auto_enable = true,
    lsp = true,
    excludes = { "lazy", "mason", "help", "NvimTree", "neominimap" },
  },
})
