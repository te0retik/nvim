return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function() require("user.plugins.which-key") end,
  },

  { -- session save/restore (buffers, tabs, windows, layout) per cwd.
    -- The start screen itself is snacks.dashboard (see user/plugins/snacks.lua);
    -- its "Restore Session" button drives this plugin.
    "folke/persistence.nvim",
    event = { "BufReadPre", "BufNewFile" },
    -- Also load on the session keys so <leader>S* work even before any file is
    -- opened (e.g. on the dashboard or in a non-modifiable buffer). Without this,
    -- <leader>S has no mapping yet and falls through to native `S` → E21 on a
    -- non-modifiable buffer. lazy registers these as prefixes and re-feeds the key
    -- after loading; the real mappings (with descriptions) live in persistence.lua.
    keys = { "<leader>Sr", "<leader>Sl", "<leader>Sd", "<leader>Sq" },
    config = function() require("user.plugins.persistence") end,
  },
}
