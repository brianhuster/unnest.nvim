--- @brief Must run lua-language-server inside a Nvim instance, because
--- $VIMRUNTIME is only available there. Also some packages like `appimage` or
--- `snap` even remove $VIMRUNTIME directory after the Nvim session is closed,
--- so command like `VIMRUNTIME = $(nvim --clean --headless +"lua
--- io.stdout:write(vim.env.VIMRUNTIME)" +q)` won't work with them.

vim.system({ "lua-language-server", "--check=.", "--configpath=.nvim.lua" }, {
	stdout = function(err, data)
		if data then
			io.stdout:write(data)
		end
		if err then
			io.stderr:write(err)
		end
	end,
	stderr = function(err, data)
		if data then
			io.stderr:write(data)
		end
		if err then
			io.stderr:write(err)
		end
	end,
}, function(out)
	os.exit(out.code)
end):wait()
