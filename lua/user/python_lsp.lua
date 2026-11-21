-- Python language servers (basedpyright + ruff) run inside Apple `container`
-- instead of on the host, so they see the interpreter and site-packages of the
-- project's own image. Mason is not involved: its macOS binaries can't run in a
-- Linux container.
--
-- Each server is `container run --rm -i` with the project root mounted read-only
-- at the same path, so file:// URIs mean the same thing on both sides. The image
-- is containers/python-lsp/Containerfile built on top of a base image picked per
-- project root (M.bases); it is built on first use. After the base image changes
-- (new dependencies), run :PythonLspRebuild.
--
-- `--rm` is done by the `container run` client, and nvim kills the client when it
-- quits, so the stopped container used to stay behind with its own copy of the
-- image file system (1.5-2 GB each). The containers are therefore named, deleted
-- after nvim quits, and every server start clears stopped ones left by any nvim.
local M = {}

local containerfile_dir = vim.fn.stdpath("config") .. "/containers/python-lsp"
local default_base = "docker.io/library/python:3.13-slim"

-- Project root (where pyproject.toml / .git is) -> base image.
M.bases = {
  -- the one backend image of the project: the app and dev dependency groups
  [vim.fn.expand("~/proj/szondi/backend")] = "szondi-backend:dev",
}

local function image_for(root)
  local base = M.bases[root] or default_base
  local tag = base:gsub("^docker%.io/library/", ""):gsub("[^%w_.-]", "-")
  return "nvim-pylsp:" .. tag, base
end

local function image_exists(image)
  return vim.system({ "container", "image", "inspect", image }):wait().code == 0
end

local building = {}

local function build(image, base, on_done)
  if building[image] then return end
  building[image] = true
  vim.notify(("python lsp: building %s from %s"):format(image, base))
  vim.system({ "container", "build", "--build-arg", "BASE=" .. base, "-t", image, containerfile_dir }, {}, function(res)
    building[image] = nil
    vim.schedule(function()
      if res.code == 0 then
        vim.notify(("python lsp: %s built"):format(image))
        if on_done then on_done() end
      else
        vim.notify(("python lsp: building %s failed\n%s"):format(image, (res.stderr or ""):sub(-1000)), vim.log.levels.ERROR)
      end
    end)
  end)
end

-- While the image is being built the shell waits for it (up to 15 min), so the
-- client's initialize just takes longer instead of failing.
local wait_then_exec = [[
i=0
until container image inspect "$1" >/dev/null 2>&1; do
  i=$((i+1)); [ "$i" -gt 900 ] && exit 1; sleep 1
done
shift; exec "$@"]]

-- Deletes every stopped container of an nvim-pylsp image, whichever nvim started it.
local function remove_stopped()
  vim.system({ "container", "list", "--all", "--format", "json" }, { text = true }, function(res)
    if res.code ~= 0 then return end
    local ok, list = pcall(vim.json.decode, res.stdout)
    if not ok or type(list) ~= "table" then return end
    local ids = {}
    for _, c in ipairs(list) do
      local cfg = type(c.configuration) == "table" and c.configuration or {}
      local ref = type(cfg.image) == "table" and cfg.image.reference or ""
      local state = type(c.status) == "table" and c.status.state or ""
      if state == "stopped" and type(ref) == "string" and ref:find("^nvim%-pylsp:") then
        ids[#ids + 1] = c.id
      end
    end
    if #ids > 0 then
      vim.system(vim.list_extend({ "container", "delete" }, ids))
    end
  end)
end

-- Names of the containers this nvim started: deleted when it quits (M.setup).
local started = {}

local function container_cmd(server, server_args, memory)
  return function(dispatchers, config)
    local root = config.root_dir or vim.fn.getcwd()
    local image, base = image_for(root)
    if not image_exists(image) then build(image, base) end
    remove_stopped()

    -- pid and a counter: two nvims, or a restart of the server, never reuse a name
    local name = ("nvim-pylsp-%s-%d-%d"):format(server, vim.uv.os_getpid(), #started + 1)
    started[#started + 1] = name

    local argv = {
      "sh", "-c", wait_then_exec, "sh", image,
      "container", "run", "--rm", "-i",
      "--name", name,
      "--memory", memory,
      "--user", ("%d:%d"):format(vim.uv.getuid(), vim.uv.getgid()),
      "-e", "HOME=/tmp",
      "-v", root .. ":" .. root .. ":ro",
      "-w", root,
      image,
    }
    vim.list_extend(argv, server_args)
    return vim.lsp.rpc.start(argv, dispatchers, { cwd = root })
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UserPythonLsp", { clear = true })

  vim.lsp.config("basedpyright", {
    cmd = container_cmd("basedpyright", { "basedpyright-langserver", "--stdio" }, "2G"),
    -- The server polls processId and exits when it isn't alive; nvim's host PID
    -- doesn't exist inside the container, so it would quit after ~3s.
    before_init = function(params) params.processId = vim.NIL end,
    settings = {
      basedpyright = {
        disableOrganizeImports = true, -- ruff does it
        analysis = { typeCheckingMode = "standard" },
      },
    },
  })
  vim.lsp.config("ruff", { cmd = container_cmd("ruff", { "ruff", "server" }, "512M") })
  vim.lsp.enable({ "basedpyright", "ruff" })

  -- The servers get a few seconds to exit on their own, then whatever is left of
  -- this nvim's containers, running or stopped, is deleted. Detached: nvim does
  -- not wait for it.
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if #started == 0 then return end
      local script = "sleep 3; container delete --force " .. table.concat(started, " ") .. " >/dev/null 2>&1"
      vim.system({ "sh", "-c", script }, { detach = true })
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      -- K should show basedpyright's hover, not ruff's rule docs
      if client and client.name == "ruff" then
        client.server_capabilities.hoverProvider = false
      end
    end,
  })

  vim.api.nvim_create_user_command("PythonLspRebuild", function()
    local client = vim.lsp.get_clients({ bufnr = 0, name = "basedpyright" })[1]
    local root = client and client.root_dir or vim.fn.getcwd()
    local image, base = image_for(root)
    build(image, base, function() vim.cmd("lsp restart basedpyright ruff") end)
  end, { desc = "Rebuild the Python LSP container image for this project" })
end

return M
