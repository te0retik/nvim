if not pcall(require, "mason-lspconfig") then
  require("user.utils").info("skipped lsp complex configuration")
  return
end

local lazydev_ok, lazydev = pcall(require, "lazydev")
if lazydev_ok then
  lazydev.setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "nvim-dap-ui", words = { "dapui" } },
    },
  })
else
  require("user.utils").info("skipped lazydev")
end

vim.o.winborder = "rounded"

local function setup_keymap()
  vim.keymap.set('n', "<leader>.l", "<cmd>:che lspconfig<cr>", {desc="LSPInfo"})
  vim.keymap.set('n', "<leader>.m", "<cmd>Mason<cr>", {desc="Mason"})

  -- K -> hover is mapped per buffer in on_attach below: Neovim maps it itself on
  -- LspAttach, but only conditionally, and when that check loses K falls through
  -- to 'keywordprg' (in Go: a `go doc` terminal split).
  -- See after/ftplugin/go.lua for why 'keywordprg' has
  -- to be cleared in Go buffers (  hover documentation).

  vim.keymap.set('n', "<C-k>", vim.lsp.buf.signature_help, {desc="󰊕 Signature Documentation"})
  vim.keymap.set('i', "<C-k>", vim.lsp.buf.signature_help, {desc="󰊕 Signature Documentation"})
  vim.keymap.set('n', "<leader>a", vim.lsp.buf.code_action, {desc=" Code Action"})
  -- In-place rename: the input floats over the symbol itself, seeded with the
  -- current name, and previews the edit live. Falls back to the stock prompt
  -- if the plugin is missing.
  vim.keymap.set('n', "<leader>lr", function()
    local ok, live_rename = pcall(require, "live-rename")
    if ok then live_rename.rename() else vim.lsp.buf.rename() end
  end, {desc="󰑕 Rename"})
  vim.keymap.set('n', "<leader>lf", vim.lsp.buf.format, {desc="Format"})
  vim.keymap.set('n', "<leader>ll", vim.diagnostic.open_float, {desc=" Line diagnostic"})

  local telescope_ok, telescope = pcall(require, "telescope.builtin")
  if telescope_ok then
    -- Put what is being looked up into the picker title: the word under the
    -- cursor for the goto pickers ("LSP References: UserService"), the file name
    -- for the ones scoped to the current buffer. Stock titles say neither.
    local for_word = function(picker, title)
      return function() picker({ prompt_title = title .. ": " .. vim.fn.expand("<cword>") }) end
    end
    local for_file = function(picker, title, opts)
      return function()
        picker(vim.tbl_extend("force", opts or {}, { prompt_title = title .. ": " .. vim.fn.expand("%:t") }))
      end
    end

    vim.keymap.set('n', "gr", for_word(telescope.lsp_references, "LSP References"),{desc=" Goto References"})
    vim.keymap.set('n', "gi", for_word(telescope.lsp_implementations, "LSP Implementations"),{desc=" Goto Implementation"})
    vim.keymap.set('n', "gd", for_word(telescope.lsp_definitions, "LSP Definitions"),{desc=" Goto Definition"})
    -- Open a goto target in another window by composing two primitives: first make
    -- a directional split of the current file (<leader>s + hjkl, see keymap.lua),
    -- then run gd/gt/gr/gi in that split. No goto-in-split machinery needed here.
    vim.keymap.set('n', "gt", for_word(telescope.lsp_type_definitions, "LSP Type Definitions"),{desc=" Goto Type Definition"})
    vim.keymap.set('n', "<leader>li", for_word(telescope.lsp_implementations, "LSP Implementations"),{desc=" Goto Implementation"})
    vim.keymap.set('n', "<leader>ls", for_file(telescope.lsp_document_symbols, "LSP Document Symbols"), {desc="󰫧 Find Document Symbols"})
    vim.keymap.set('n', "<leader>lS", telescope.lsp_dynamic_workspace_symbols, {desc="󰫧 Find Workspace Symbols"})
    vim.keymap.set('n', "<leader>ld", for_file(telescope.diagnostics, "Diagnostics", { bufnr = 0 }), {desc=" Document diagnostics"})
    vim.keymap.set('n', "<leader>lD", telescope.diagnostics, {desc=" Workspace Diagnostics"})
  else
    require("user.utils").info("skipped lsp telescope bindings")
  end

  vim.keymap.set('n', 'gc', vim.lsp.buf.declaration, {desc='Goto Declaration'})
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

  -- Do not rely on vim.lsp._set_defaults() for this: it skips K when any other
  -- K mapping already exists or 'keywordprg' was touched by something outside
  -- $VIMRUNTIME, and then K falls back to 'keywordprg' instead of hovering.
  if client and client:supports_method("textDocument/hover") then
    map("K", require("user.utils").hover, "Hover Documentation")
  end
end

local function setup_lsp()
  require('mason').setup()

  local servers = {
    gopls = {
      settings = {
        gopls = {
          codelenses = {
            vulncheck = false,        -- hide "Run govulncheck to check for vulnerabilities" lens
            run_govulncheck = false,  -- older gopls name for the same lens
          },
        },
      },
    },
    sqls = {},
    marksman = {}, -- markdown: link/heading completion, goto, broken-link diagnostics
    lua_ls = {
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    },
  }

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local blink_ok, blink = pcall(require, "blink.cmp")
  if blink_ok then
    capabilities = blink.get_lsp_capabilities(capabilities)
  end

  vim.lsp.config("*", { capabilities = capabilities })
  for name, cfg in pairs(servers) do
    vim.lsp.config(name, cfg)
  end
  -- Python servers run in a container, not from Mason (see user/python_lsp.lua)
  require("user.python_lsp").setup()

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
    callback = function(ev) on_attach(vim.lsp.get_client_by_id(ev.data.client_id), ev.buf) end,
  })

  require("mason-lspconfig").setup({
    ensure_installed = vim.tbl_keys(servers),
  })

end

setup_keymap()
setup_lsp()
