-- Reload the Lua config without restarting Neovim.
-- `:so $MYVIMRC` alone does NOT work: required modules are cached in
-- package.loaded, so a repeat require() returns the cached copy and the edited
-- file is never re-read. So we drop the cache for our own namespaces first,
-- then re-source init.lua (which re-requires them fresh).
--
-- We keep `init.plugin_manager` cached, though: re-sourcing init.lua re-requires
-- it, and running `lazy.setup()` twice makes lazy.nvim warn
-- ("Re-sourcing your config is not supported with lazy.nvim"). Leaving it in
-- package.loaded makes the repeat require() a no-op, so lazy.setup() runs once.
function _G.ReloadConfig()
	for name, _ in pairs(package.loaded) do
		if (name:match("^user") or name:match("^init")) and name ~= "init.plugin_manager" then
			package.loaded[name] = nil
		end
	end

	dofile(vim.env.MYVIMRC)
	vim.notify("Config reloaded", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("ReloadConfig", ReloadConfig, { desc = "reload init.* and user.* lua modules" })

-- ── :Restart — full restart with a session round-trip ──────────────────────
-- :restart (nvim 0.12+) starts a fresh instance on the same UI, which is the
-- only reliable way to re-apply plugin spec/config edits — but it drops the
-- window/tab layout. So: save the session (persistence.nvim), leave a marker
-- file, restart; on the next startup the marker triggers a one-shot restore.
local restart_marker = vim.fn.stdpath("state") .. "/restore_session_after_restart"

function _G.RestartWithSession()
	-- persistence is lazy-loaded; require() makes lazy pull it in. Its pre_save
	-- hook also closes nvim-tree so the sidebar doesn't pollute the session.
	local saved = pcall(function() require("persistence").save() end)
	if saved then
		local fd = io.open(restart_marker, "w")
		if fd then fd:write("1"); fd:close() end
	end
	vim.cmd("silent! wa") -- flush file buffers; restart! discards what's left
	vim.cmd("restart!")
end

vim.api.nvim_create_user_command("Restart", RestartWithSession,
	{ desc = "save session, restart nvim, restore session" })

vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy", -- plugins are up by then; dashboard yields gracefully
	group = vim.api.nvim_create_augroup("user_restart_restore", { clear = true }),
	callback = function()
		if vim.fn.filereadable(restart_marker) == 1 then
			os.remove(restart_marker) -- one-shot: a plain launch must not restore
			pcall(function() require("persistence").load() end)
		end
	end,
})
