local lsp_log = require('vim.lsp.log')

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

  -- Pass the WHOLE file to the preview (not a ±slice) so scrolling inside the
  -- popup reveals the entire buffer, and line numbers in the float match the
  -- source 1:1. The window itself is kept small via max_height/max_width below;
  -- the cursor is parked on the definition line afterwards.
  local lines = vim.api.nvim_buf_get_lines(loc_bufnr, 0, -1, false)
  config.max_height = 18
  config.max_width = 100

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

  -- Park the view on the definition line and center it. Line count is the same
  -- as the source buffer since we copied the whole file, so range.start.line
  -- (0-indexed) maps to the float row directly.
  local def_row = math.min((range.start.line or 0) + 1, vim.api.nvim_buf_line_count(float_bufnr))
  vim.api.nvim_win_set_cursor(float_winnr, { def_row, 0 })
  vim.api.nvim_win_call(float_winnr, function() vim.cmd("normal! zz") end)
  vim.wo[float_winnr].cursorline = true
  vim.wo[float_winnr].number = true

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
  if vim.islist(result) then
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

vim.keymap.set('n', "<leader>lh", definition_hover, {desc=" Hover Definition"})
