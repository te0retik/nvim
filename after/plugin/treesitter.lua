
local ok, nvim_treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then
  require('user.utils').info("skipped treesitter")
	return
end


-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = {
      'c',
      'cpp',
      'go',
      'lua',
      'python',
      'rust',
      'tsx',
      'sql',
      'http',
      'javascript',
      'typescript',
      'vimdoc',
      'vim',
      'bash',
      'json',
      'yaml',
      'toml',
      'make',
      'markdown',
      'git_config',
      'git_rebase',
      'gitattributes',
      'gitcommit',
      'gitignore',
    },

    sync_install = false, -- Install parsers synchronously (only applied to `ensure_installed`)
    auto_install = false, -- Autoinstall languages that are not installed

    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      --swap = {
      --  enable = true,
      --  swap_next = {
      --    ['<leader>a'] = '@parameter.inner',
      --  },
      --  swap_previous = {
      --    ['<leader>A'] = '@parameter.inner',
      --  },
      --},
    },
  }

  local context = require("treesitter-context")
  vim.keymap.set("n", "cc", context.go_to_context)
end, 0)
