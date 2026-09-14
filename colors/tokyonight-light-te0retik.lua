-- Real-colorscheme wrapper around the highlight dump in
-- lua/user/colors/tokyonight_light_te0retik.lua. Loads the base theme first,
-- then applies the dump on top: entries with `default = true` only fill gaps,
-- explicit fg/bg entries override the base — i.e. "tokyonight-day + my tweaks".
-- Living in colors/ makes it a first-class scheme: it shows up in the
-- <leader>.c telescope picker and persists via save_colorscheme().
vim.o.background = "light"
vim.cmd.colorscheme("tokyonight-day")
vim.g.colors_name = "tokyonight-light-te0retik"

package.loaded["user.colors.tokyonight_light_te0retik"] = nil -- re-read on every :colorscheme
require("user.color").apply_highlights(require("user.colors.tokyonight_light_te0retik"))
