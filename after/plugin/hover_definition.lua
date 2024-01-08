local lsp_log = require('vim.lsp.log')

local nmap = require("user.utils").nnoremap
local dumps = require("user.utils").table_to_string


local function hover_text_at_location(location, offset_encoding, ctx)
  -- print(dumps(location))
  local config = { border = "rounded" }
  config.focus_id = ctx.method

  if vim.api.nvim_get_current_buf() ~= ctx.bufnr then
    return -- Ignore result since buffer changed. This happens for slow language servers.
  end

  local uri = location.uri or location.targetUri
  if uri == nil then
    return false
  end
  if offset_encoding == nil then
    vim.notify_once('show_document must be called with valid offset encoding', vim.log.levels.WARN)
  end
  local loc_bufnr = vim.uri_to_bufnr(uri)

  if not vim.api.nvim_buf_is_loaded(loc_bufnr) then
    vim.fn.bufload(loc_bufnr)
  end

  local range = location.targetRange or location.range or location.originSelectionRange

  local start_lineno = range.start.line
  if start_lineno >= 5 then
    start_lineno = start_lineno - 5
  end

  local end_lineno = range["end"].line
  if end_lineno - start_lineno < 20 then
    end_lineno = end_lineno + 20
  end

  local lines = vim.api.nvim_buf_get_lines(loc_bufnr, start_lineno, end_lineno, false)
  -- print("lines=")
  -- print(lines)
  -- print("  #" .. #lines)

  local syntax = vim.api.nvim_buf_get_option(ctx.bufnr, "syntax")
  if syntax == '' then
    -- When no syntax is set, we use filetype as fallback. This might not result
    -- in a valid syntax definition. See also ft detection in stylize_markdown.
    -- An empty syntax is more common now with TreeSitter, since TS disables syntax.
    syntax = vim.api.nvim_buf_get_option(ctx.bufnr, "filetype")
  end
  if syntax == '' then
    syntax = "plaintext"
  end
  local float_bufnr, float_winnr = vim.lsp.util.open_floating_preview(lines, syntax, config)

  -- local filetype = vim.api.nvim_buf_get_option(float_bufnr, "filetype")
  -- print("filetype=" .. filetype)
  -- local filetype
  -- if not filetype then
  local filetype = vim.filetype.match({ filename = uri })
  vim.api.nvim_buf_set_option(float_bufnr, "filetype", filetype)
  -- end
  vim.treesitter.start(float_bufnr)

  return float_bufnr, float_winnr
end

local function _defenition_location(result, ctx)
  if result == nil or vim.tbl_isempty(result) then
    local _ = lsp_log.info() and lsp_log.info(ctx.method, 'No location found')
    return nil
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)

  -- textDocument/definition can return Location or Location[]
  -- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_definition
  if vim.tbl_islist(result) then
    -- local title = 'LSP locations'
    local items = vim.lsp.util.locations_to_items(result, client.offset_encoding)

    --FIXME use telescope for multiple results
    -- if config.on_list then
    --   assert(type(config.on_list) == 'function', 'on_list is not a function')
    --   config.on_list({ title = title, items = items })
    -- else
    if #result == 1 then
      return result[1]
      -- hover_text_at_location(result[1], client.offset_encoding, ctx)
    else
      vim.fn.setqflist({}, ' ', { title = 'LSP locations', items = items })
      vim.api.nvim_command('botright copen')
    end
    -- end
  else
    return result
    -- hover_text_at_location(result, client.offset_encoding, ctx)
  end
end

local function definition_hover_handler(err, result, ctx, config)
  local location = _defenition_location(result, ctx)
  if location then
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    -- FIXME use vim.lsp.util.preview_location()
    hover_text_at_location(location, client.offset_encoding, ctx)
  end
end

local function definition_hover()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/definition", params, definition_hover_handler)
end

nmap("<leader>lh", definition_hover, " Hover Definition")
