local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_ok then
  require('user.utils').info('skipped lsp complex configiguration')
  return
end

local nmap = require("user.utils").nnoremap
local map = require("user.utils").noremap

local neodev_ok, neodev = pcall(require, "neodev")
if neodev_ok then
  -- NOTE must setup before LSP 
  neodev.setup({}) -- Setup neovim lua configuration
else
  require('user.utils').info("skipped neodev")
end

local hover_border_style = "rounded" -- or "single"
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = hover_border_style })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = hover_border_style })

local function setup_keymap()
  nmap("<leader>.l", function() require "lspconfig.ui.lspinfo" () end, "LSPInfo")
  nmap("<leader>.m", "<cmd>Mason<cr>", "Mason")

  nmap("K", vim.lsp.buf.hover, "Hover Documentation") -- See `:help K` for why this keymap
  nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
  map('i', "<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
  nmap("<leader>a", vim.lsp.buf.code_action, "Code Action")
  nmap("<leader>lr", vim.lsp.buf.rename, "Rename")
  nmap("<leader>lf", vim.lsp.buf.format, "Format")
  nmap("<leader>ll", vim.diagnostic.open_float, "Line diagnostic")

  local telescope_ok, telescope = pcall(require, "telescope.builtin")
  if telescope_ok then
    nmap("gr", telescope.lsp_references, "Goto References")
    nmap("gi", telescope.lsp_implementations, "Goto Implementation")
    nmap("gd", telescope.lsp_definitions, "Goto Definition")
    nmap("gt", telescope.lsp_type_definitions, "Goto Type Definition")
    nmap("<leader>ls", telescope.lsp_document_symbols, "Find Document Symbols")
    nmap("<leader>lS", telescope.lsp_dynamic_workspace_symbols, "Find Workspace Symbols")
    nmap("<leader>ld", function() telescope.diagnostics({ bufnr = 0 }) end, "Document diagnostics")
    nmap("<leader>lD", telescope.diagnostics, "Workspace Diagnostics")
  else
    require("user.utils").info("skipped lsp telescope bindings")
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

  -- map("[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
  -- map('gf', vim.lsp.buf.definition, 'Goto Definition')
  -- map('gc', vim.lsp.buf.declaration, 'Goto Declaration')
  -- map('gE', vim.lsp.buf.lsp_type_definition, 'Goto Type definition')
  -- map('<leader>ly', vim.lsp.buf.workspace_symbol, 'Symbol')
  -- map('<leader>wa', vim.lsp.buf.add_workspace_folder, 'Workspace Add Folder')
  -- map('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Workspace Remove Folder')
end

--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(client, bufnr)
  local map = function(keys, func, desc, mode)
    local mmode = 'n'
    if mode then
      mmode = mode
    end
    vim.keymap.set(mmode, keys, func, { buffer = bufnr, desc = desc })
  end

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

  -- local status_ok, illuminate = pcall(require, "illuminate")
  -- if status_ok then
  --   illuminate.on_attach(client)
  -- end

  local hover_close = function(base_win_id)
    -- https://vi.stackexchange.com/questions/37225/how-do-i-close-a-hovered-window-with-lsp-information-escape-does-not-work
    local windows = vim.api.nvim_tabpage_list_wins(0)
    for _, win_id in ipairs(windows) do
      if win_id ~= base_win_id then
        local win_cfg = vim.api.nvim_win_get_config(win_id)
        if win_cfg.relative == "win" and win_cfg.win == base_win_id then
          vim.api.nvim_win_close(win_id, {})
          break
        end
      end
    end
  end

  map("q", function() hover_close(vim.api.nvim_get_current_win()) end, "close hover")
end

local function setup_lsp()
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
  capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

  mason_lspconfig.setup({
    ensure_installed = vim.tbl_keys(servers),
  })
  mason_lspconfig.setup_handlers({
    function(server_name)
      lspconfig[server_name].setup {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = servers[server_name],
        filetypes = (servers[server_name] or {}).filetypes,
      }
    end,
  })
end

setup_keymap()
setup_lsp()
