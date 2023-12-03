local ok, rest = pcall(require, "rest-nvim")
if not ok then
  require('user.utils').info("skipped rest-nvim")
  return
end


rest.setup({
  result = {
    show_curl_command = true,
    show_statistics = true,
  }
})

vim.keymap.set("n", "<leader>tt", function() rest.run() end, { desc = "Execute request" })
vim.keymap.set("n", "<leader>tp", function() rest.run(true) end, { desc = "Preview request" })

local rest_curl = require("rest-nvim.curl")
local utils = require("rest-nvim.utils")

vim.api.nvim_create_autocmd("User", {
  pattern = "RestStopRequest",
  callback = function(event)
    -- receives a table argument with these keys:
    -- • id: (number) autocommand id
    -- • event: (string) name of the triggered event |autocmd-events|
    -- • group: (number|nil) autocommand group id, if any
    -- • match: (string) expanded value of |<amatch>|
    -- • buf: (number) expanded value of |<abuf>|
    -- • file: (string) expanded value of |<afile>|
    -- • data: (any) arbitrary data passed from |nvim_exec_autocmds()|
    local curl_response_bufnr = rest_curl.get_or_create_buf()
    local res_filename = "./last-respose.json"
    -- local json = vim.fn.json_encode()

    if not event.data or not event.data.res or not event.data.res.body or #event.data.res.body == 0 then
      print("save response skipped: response body is empty")
    end

    local res_body = event.data.res.body:gsub("\n", "")
    -- local res_body = event.data.res.body
    -- print(vim.inspect(res_body))
    local info_str
    local writef_res_ok, writef_res = pcall(vim.fn.writefile, { res_body }, res_filename, 'bs')
    if writef_res_ok then
      info_str = '' ..
          "result saved to tmp file " .. res_filename ..
          " total " .. #event.data.res.body .. "b"
      -- "request_id:" .. event.data.request_id ..
      -- " method:" .. event.data.method
    else
      info_str = 'write json file error'
    end


    utils.write_block(
      curl_response_bufnr,
      { info_str },
      true)

    print(info_str)
  end
})

local rest_config = require("rest-nvim.config")
local telescope_ok, telescope = pcall(require, "telescope.builtin")
if telescope_ok then
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local function select_rest_environment()
    telescope.find_files({
      hidden = true,
      no_ignore = true,
      search_file = ".env*",
      prompt_title = "rest-nvim .env file",
      attach_mappings = function(bufnr, _)
        actions.select_default:replace(function()
          actions.close(bufnr)

          local selection = action_state.get_selected_entry()
          local path = selection[1]

          rest_config.set({ env_file = path })

          vim.print([['rest-nvim.config'.set({ env_file = ']] .. path .. "' })")
        end)

        return true
      end
    })

    -- or using vim.ui.select
    -- vim.ui.select(
    --     { ".env_local", ".env_dev", ".env_prod" },
    --     {
    --         prompt = "Select HTTP envronment file",
    --     },
    --     function(choise)
    --       config.set({ env_file = choise })
    --       vim.print("HTTP environment set to "..path)
    --     end
    -- )
  end

  vim.keymap.set("n", "<leader>tT", select_rest_environment, { desc = "Select 'rest-nvim' Environment file" })
end
