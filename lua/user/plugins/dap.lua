local status_ok, dap = pcall(require, "dap")
if not status_ok then
  require("user.utils").info("skipped nvim-dap")
  return
end

-- FIXME keymap
vim.keymap.set("n", "<leader>dc", dap.continue, {desc=" Continue /   Start"}) -- launches a debugger if there is no active session
vim.keymap.set("n", "<leader>ds", dap.step_over, {desc=" Step Over"})
vim.keymap.set("n", "<leader>di", dap.step_into, {desc=" Step Into"})
vim.keymap.set("n", "<leader>do", dap.step_out, {desc=" Step Out"})
vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, {desc=" Toggle Breakpoint"})
vim.keymap.set("n", "<leader>dj", dap.run_to_cursor, {desc=" Run to Cursor"})
vim.keymap.set("n", "<leader>dr", dap.restart, {desc=" Restart"})
vim.keymap.set("n", "<leader>dq", dap.terminate, {desc=" Terminate"})


----------------------------------------
-- C/C++/Rust
----------------------------------------
-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#ccrust-via-lldb-vscode

dap.adapters.lldb = {
  type = 'executable',
  command = '/usr/bin/lldb-vscode', -- must be absolute path
  name = 'lldb'
}

local cConfig = {
  name = 'Launch',
  type = 'lldb',
  request = 'launch',
  program = function()
    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
  end,
  cwd = '${workspaceFolder}',
  stopOnEntry = false,
  args = {},
  runInTerminal = false, -- read docs before changing
}

dap.configurations.c = { cConfig }
dap.configurations.cpp = dap.configurations.c

local rustConfig = {}
for k,v in pairs(cConfig) do rustConfig[k] = v end

-- Add rust types
rustConfig.initCommands = function()
  -- Find out where to look for the pretty printer Python module
  local rustc_sysroot = vim.fn.trim(vim.fn.system('rustc --print sysroot'))

  local script_import = 'command script import "' .. rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py"'
  local commands_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_commands'

  local commands = {}
  local file = io.open(commands_file, 'r')
  if file then
    for line in file:lines() do
      table.insert(commands, line)
    end
    file:close()
  end
  table.insert(commands, 1, script_import)

  return commands
end

dap.configurations.rust = { rustConfig }

----------------------------------------
-- Go
----------------------------------------

dap.adapters.delve = {
  type = "server",
  port = "${port}",
  executable = {
    command = "dlv",
    args = {"dap", "-l", "127.0.0.1:${port}"},
  },
}

-- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
dap.configurations.go = {
  {
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}"
  },
  {
    type = "delve",
    name = "Debug test (go.mod)",
    request = "launch",
    mode = "test",
    program = "./${relativeFileDirname}"
  },
}
