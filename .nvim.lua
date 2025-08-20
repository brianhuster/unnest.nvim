local luarc = {
	Lua = {
		workspace = {
			library = {
				os.getenv("VIMRUNTIME"),
			},
			checkThirdParty = false,
		},
		runtime = {
			version = "Lua 5.1",
			path = {
				"lua/?.lua",
				"lua/?/init.lua",
				"?.lua",
				"?/init.lua",
			},
		}
	}
}

if vim and vim.fn.has("nvim-0.11") == 1 then
	vim.lsp.config.lua_ls = {
		filetypes = { "lua" },
		root_markers = { "lua" },
		settings = luarc,
	}
end

return luarc
