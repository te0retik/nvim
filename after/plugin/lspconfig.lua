local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_ok then
  require('user.utils').info('skipped lsp complex configiguration')
  return
end

local neodev_ok, neodev = pcall(require, "neodev")
if neodev_ok then
  neodev.setup({})  -- Setup neovim lua configuration
else
  require('user.utils').info("skipped neodev")
  print("skipped neodev")
end

--local _border = "single"
local _border = "rounded"
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = _border })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = _border })

local function setup_keymap()
  vim.keymap.set('n', "<leader>.l", function() require 'lspconfig.ui.lspinfo' () end, { desc = 'LSPInfo' })
  vim.keymap.set('n', "<leader>.m", '<cmd>Mason<cr>', { desc = 'Mason' })

  local map = function(keys, func, desc, mode)
    local mmode = 'n'
    if mode then
      mmode = mode
    end
    vim.keymap.set(mmode, keys, func, { desc = desc })
  end

  local telescope_ok, telescope = pcall(require, "telescope.builtin")
  if telescope_ok then
    map('gr', telescope.lsp_references, 'Goto References')
    map('gi', telescope.lsp_implementations, 'Goto Implementation')
    map('gd', telescope.lsp_definitions, 'Goto Definition')
    map('gt', telescope.lsp_type_definitions, 'Goto Type Definition')
    map('<leader>ls', telescope.lsp_document_symbols, 'Find Document Symbols')
    map('<leader>lS', telescope.lsp_dynamic_workspace_symbols, 'Find Workspace Symbols')
    map('<leader>ld', function() telescope.diagnostics({ bufnr = 0 }) end, 'Document diagnostics')
    map('<leader>lD', telescope.diagnostics, 'Workspace Diagnostics')
  else
    require('user.utils').info('skipped lsp telescope bindings')
  end

  -- local trouble_ok, trouble = pcall(require, "trouble")
  -- local trouble_ok = false -- disable trouble bindings
  -- if trouble_ok then
  --   -- map('<leader>lt', function () trouble.open("document_diagnostics") end, 'Diagnostics')
  --   map('gR', function() trouble.open("lsp_references") end, 'References')
  --   map('gI', function() trouble.open("lsp_implementations") end, "Implementations")
  --   map('gD', function() trouble.open("lsp_definitions") end, 'Definitions')
  --   map('gT', function() trouble.open("lsp_type_definitions") end, 'Definitions')
  -- else
  --   require('user.utils').info('skipped lsp trouble bindings')
  -- end

  map('K', vim.lsp.buf.hover, 'Hover Documentation') -- See `:help K` for why this keymap
  map('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
  map('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation', 'i')
  map('<leader>a', vim.lsp.buf.code_action, 'Code Action')
  map('<leader>lr', vim.lsp.buf.rename, 'Rename')
  map('<leader>lf', vim.lsp.buf.format, 'Format')
  map('<leader>ll', vim.diagnostic.open_float, 'Line diagnostic')

  -- map("[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
  -- map('gf', vim.lsp.buf.definition, 'Goto Definition')
  -- map('gc', vim.lsp.buf.declaration, 'Goto Declaration')
  -- map('gE', vim.lsp.buf.lsp_type_definition, 'Goto Type definition')
  -- map('<leader>ly', vim.lsp.buf.workspace_symbol, 'Symbol')
  -- map('<leader>wa', vim.lsp.buf.add_workspace_folder, 'Workspace Add Folder')
  -- map('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Workspace Remove Folder')
end

setup_keymap()

--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(client, bufnr)
  local map = function(keys, func, desc, mode)
    local mmode = 'n'
    if mode then
      mmode = mode
    end
    vim.keymap.set(mmode, keys, func, { buffer = bufnr, desc = desc })
  end

  -- vim.api.nvim_buf_create_user_command(bufnr, 'Format', function()
  -- vim.lsp.buf.format()
  -- end, { desc = 'Format current buffer' })

  -- highlight word under cursor
  -- if client.supports_method "textDocument/documentHighlight" then
  --   vim.api.nvim_create_augroup("lsp_document_highlight", {clear = false})
  --   vim.api.nvim_clear_autocmds {buffer = bufnr, group = "lsp_document_highlight"}
  --   vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  --     group = "lsp_document_highlight",
  --     buffer = bufnr,
  --     callback = vim.lsp.buf.document_highlight,
  --   })
  --   vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  --     group = "lsp_document_highlight",
  --     buffer = bufnr,
  --     callback = vim.lsp.buf.clear_references,
  --   })
  -- else
  --   require('user.utils').info("skipped textDocument/documentHighlight")
  -- end

  -- lsp_highlight_document
  -- local status_ok, illuminate = pcall(require, "illuminate")
  -- if not status_ok then
  --   return
  -- end
  -- illuminate.on_attach(client)
end

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
local mason_lspconfig = require("mason-lspconfig") -- Ensure the servers above are installed
mason_lspconfig.setup()

local servers = {
  -- clangd = {},
  -- rust_analyzer= {},
  gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  -- tsserver = {},
  -- html = { filetypes = { 'html', 'twig', 'hbs'} },
  -- yamlls = {},
  -- jsonls = {},
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}
mason_lspconfig.setup_handlers {
  function(server_name)
    lspconfig[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes,
    }
  end,
}
