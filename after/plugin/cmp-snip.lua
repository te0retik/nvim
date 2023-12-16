local cmp_ok, cmp = pcall(require, "cmp")
if not cmp_ok then
  require("user.utils").info("skipped cmp")
  return
end

local build_cmp_format = function(menu_icons)
  local fallback_kind_icons = {
    Text = "",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰇽",
    Variable = "󰂡",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    Reference = "",
    File = "󰈙",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "󰅲",
  }

  return function(entry, vim_item)
    vim_item.kind = string.format('%s %s', fallback_kind_icons[vim_item.kind], vim_item.kind)
    vim_item.menu = (menu_icons)[entry.source.name]
    return vim_item
  end
end

local cmp_menu_icons = {
  buffer = "󰕸",
  nvim_lsp = "",
  luasnip = " <  >",
  nvim_lua = "",
  latex_symbols = "[LaTeX]",
  treesitter = "",
}

local cmp_format = build_cmp_format(cmp_menu_icons)

local lspkind_ok, lspkind = pcall(require, "lspkind")
if lspkind_ok then
  lspkind.init({
    mode = 'symbol_text',
    preset = 'codicons',
  })
  cmp_format = lspkind.cmp_format({ menu = cmp_menu_icons })
end

local luasnip_ok, luasnip = pcall(require, "luasnip")

cmp.setup({
  formatting = { format = cmp_format },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(), -- border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
  },
  snippet = {
    expand = function(args)
      if luasnip_ok then
        luasnip.lsp_expand(args.body)
      end
    end,
  },
  mapping = cmp.mapping.preset.insert {
    -- ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    -- ['<C-e>'] = cmp.mapping.abort,
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm {
      select = true,
      behavior = cmp.ConfirmBehavior.Replace,
    },
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip_ok and luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ["<S-Tab>"] = cmp.mapping(
      function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip_ok and luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end,
      { 'i', 's' }
    ),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "treesitter" },
    { name = "nvim_lua" },
    -- { name = "git" },
  },
})

cmp.setup.filetype("gitcommit", {
  sources = cmp.config.sources({
    { name = "cmp_git" },
    { name = "git" },
  }, {
    { name = "buffer" },
  })
})

cmp.setup.cmdline("/", {
  -- completion = { autocomplete = false },
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" }
    -- { name = 'buffer', opts = { keyword_pattern = [=[[^[:blank:]].*]=] } }
  }
})

-- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(":", {
  -- completion = { autocomplete = true},
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources(
    { { name = "path" } },
    { { name = "cmdline" } }
  )
})
