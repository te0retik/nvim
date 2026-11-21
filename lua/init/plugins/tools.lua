return {
  { -- http client (kulala.nvim — replaces rest.nvim; no luarocks deps)
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    config = function() require("user.plugins.kulala") end,
  },

  { -- markdown rendered in-buffer (headings, lists, checkboxes, tables, code
    -- blocks, links, callouts). Rendering is per *mode*: in normal/command/
    -- terminal mode the buffer is rendered, in insert/visual mode the text is
    -- shown raw so editing is unobstructed. <leader>tm toggles rendering
    -- for the current buffer, <leader>tM globally.
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      render_modes = { "n", "c", "t" },
      completions = { blink = { enabled = true } }, -- checkbox / callout completion in blink.cmp
      heading = { position = "inline" },
      code = { width = "block", left_pad = 1, right_pad = 1 },
    },
    keys = {
      { "<leader>tm", "<cmd>RenderMarkdown buf_toggle<cr>", ft = "markdown", desc = "󰍔 Markdown render (this buffer)" },
      { "<leader>tM", "<cmd>RenderMarkdown toggle<cr>",    ft = "markdown", desc = "󰍔 Markdown render (all buffers)" },
    },
  },

  { -- DB
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = "DBUIToggle",
    lazy = true,
    init = function()
      vim.g.db_ui_save_location = "~/.config/db_ui"
      vim.keymap.set("n", "<leader>td", "<cmd>DBUIToggle<cr>", { desc = " Database" })
    end,
  },

  { -- scrollbar with diagnostics/git-hunk/search marks; hlslens renders the
    -- match counter lens and feeds search marks to the bar
    "petertriho/nvim-scrollbar",
    event = "VeryLazy",
    dependencies = { "kevinhwang91/nvim-hlslens", "lewis6991/gitsigns.nvim" },
    config = function() require("user.plugins.scrollbar") end,
  },

  { -- code minimap (VS Code style), toggled on demand — see user/plugins/scrollbar.lua
    "Isrothy/neominimap.nvim",
    event = "VeryLazy",
    init = function()
      vim.g.neominimap = {
        auto_enable = false, -- enabled by hand: <leader>.M / <leader>.v cycle
        exclude_filetypes = { "NvimTree", "lazy", "TelescopePrompt", "help" },
        -- init.lua sets cursorlineopt="number,line" globally, but the map window
        -- has no number column — keep just "line" there
        winopt = function(opt) opt.cursorlineopt = "line" end,
        -- the map floats flush against the window's right edge by default,
        -- covering the column where nvim-scrollbar draws; leave that column free
        -- so bar + map can be shown together (<leader>.v "both" mode)
        float = { margin = { right = 1 } },
        -- paint lines with search matches (same source as hlslens: @/ register
        -- + v:hlsearch, so the map mirrors the hlslens markers); off by default
        search = { enabled = true },
        handlers = {
          { -- staged hunks: the built-in git handler only shows worktree hunks
            name = "Staged Git Signs",
            mode = "sign",
            namespace = vim.api.nvim_create_namespace("neominimap_git_staged"),
            init = function()
              -- staged sign colors: dimmed GitSignsStaged* fg, falling back to
              -- the regular GitSigns* groups if gitsigns isn't loaded yet
              for _, kind in ipairs({ "Add", "Change", "Delete" }) do
                local hl = vim.api.nvim_get_hl(0, { name = "GitSignsStaged" .. kind, link = false })
                if not hl.fg then hl = vim.api.nvim_get_hl(0, { name = "GitSigns" .. kind, link = false }) end
                vim.api.nvim_set_hl(0, "NeominimapGitStaged" .. kind .. "Sign",
                  { fg = hl.fg, default = true })
              end
            end,
            autocmds = {
              {
                event = "User",
                opts = {
                  pattern = "GitSignsUpdate",
                  desc = "Update staged git annotations",
                  get_buffers = function(args)
                    return args.data and args.data.buffer or nil
                  end,
                },
              },
            },
            get_annotations = function(bufnr)
              local ok, gs_cache = pcall(require, "gitsigns.cache")
              local cached = ok and gs_cache.cache[bufnr] or nil
              local hunks = cached and cached.hunks_staged or nil
              if not hunks then return {} end
              local icons = { add = "+ ", change = "~ ", delete = "- " }
              local ids = { add = 1, change = 2, delete = 3 }
              local kinds = { add = "Add", change = "Change", delete = "Delete" }
              local annotations = {}
              for _, hunk in ipairs(hunks) do
                local start = math.max(1, hunk.added.start)
                annotations[#annotations + 1] = {
                  lnum = start,
                  end_lnum = start + math.max(0, hunk.added.count - 1),
                  id = ids[hunk.type],
                  priority = 5, -- below the built-in git handler (6)
                  icon = icons[hunk.type],
                  highlight = "NeominimapGitStaged" .. kinds[hunk.type] .. "Sign",
                }
              end
              return annotations
            end,
          },
        },
      }
    end,
  },

  -- ============================================================
  -- Disabled plugins — flip `enabled = true` to activate, then
  -- the corresponding after/plugin/<name>.lua will be picked up.
  -- ============================================================
  { "akinsho/toggleterm.nvim",         enabled = false },
  { "lewis6991/hover.nvim",            enabled = false },
  { "ThePrimeagen/harpoon",            enabled = false, dependencies = "nvim-lua/plenary.nvim" },
  { "folke/trouble.nvim",              enabled = true,  dependencies = "nvim-tree/nvim-web-devicons" },
  { "ruifm/gitlinker.nvim",            enabled = false, dependencies = "nvim-lua/plenary.nvim" },
}
