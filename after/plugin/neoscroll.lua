local ok, neoscroll = pcall(require, "neoscroll")
if not ok then
  require('user.utils').info('skipped neoscroll')
  return
end

neoscroll.setup({
  -- All these keys will be mapped to their corresponding default scrolling animation
  -- mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
  easing_function = "quadratic",
  hide_cursor = false,          -- Hide cursor while scrolling
  stop_eof = true,              -- Stop at <EOF> when scrolling downwards
  respect_scrolloff = false,    -- Stop scrolling when the cursor reaches the scrolloff margin of the file
  cursor_scrolls_alone = false, -- The cursor will keep on scrolling even if the window cannot scroll further
  pre_hook = nil,               -- Function to run before the scrolling animation starts
  post_hook = nil,              -- Function to run after the scrolling animation ends
  performance_mode = false,     -- Disable "Performance Mode" on all buffers
})

require('neoscroll.config').set_mappings({
  ["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "80" } },
  ["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "80" } },
  ["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "100" } },
  ["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "100" } },
  ["<C-y>"] = { "scroll", { "-0.10", "false", "80" } },
  ["<C-e>"] = { "scroll", { "0.10", "false", "80" } },
  ["zt"] = { "zt", { "80" } },
  ["zz"] = { "zz", { "80" } },
  ["zb"] = { "zb", { "80" } },
  ["G"] = { "G", { "80" } },
  ["gg"] = { "gg", { "80" } },
})
