--- @brief Must run lua-language-server inside a Nvim instance, because
--- $VIMRUNTIME is only available there. Also some packages like `appimage` or
--- `snap` even remove $VIMRUNTIME directory after the Nvim session is closed,
--- so command like `VIMRUNTIME = $(nvim --clean --headless +"lua
--- io.stdout:write(vim.env.VIMRUNTIME)" +q)` won't work with them.

---@param err string?
---@param out string?
local function handle_output(err, out)
	if err then
		io.stderr:write(err)
	end
	if out then
		io.stdout:write(out)
	end
end

vim.system({ "lua-language-server", "--check=.", "--configpath=.nvim.lua" }, {
	text = true,
	stdout = handle_output,
	stderr = handle_output,
}, function(out)
	os.exit(out.code)
end):wait()
