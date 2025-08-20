local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)

local xdg_config_home = "Xtest/xdg/config"
local xdg_data_home = "Xtest/xdg/share"
local tmpdir = "Xtest/tmp"
vim.env.XDG_CONFIG_HOME = xdg_config_home
vim.env.XDG_DATA_HOME = xdg_data_home
vim.env.TMPDIR = tmpdir

vim.fn.mkdir(tmpdir, "p")
vim.fn.mkdir(xdg_config_home .. "/nvim", "p")

vim.fn.writefile({
	"vim.opt.rtp:prepend [[" .. vim.fn.getcwd() .. "]]",
	"vim.v.testing = 1",
}, xdg_config_home .. "/nvim/init.lua")

vim.fn.system({
	"git",
	"clone",
	"--depth=1",
	"--branch",
	"v1.9.0",
	"https://github.com/lunarmodules/luassert",
	"Xtest/luassert",
})

vim.fn.system({
	"git",
	"clone",
	"--depth=1",
	"--branch",
	"v1.4.1",
	"https://github.com/lunarmodules/say",
	"Xtest/say",
})

os.rename("Xtest/luassert/src", "Xtest/luassert/luassert")

for _, dir in ipairs({ "Xtest/luassert/", "Xtest/say/src/" }) do
	for _, path in ipairs({ "?.lua", "?/init.lua" }) do
		package.path = package.path .. ";" .. dir .. "/" .. path
	end
end

for _, file in ipairs(vim.fn.globpath(cwd, "spec/**/*_spec.lua", true, true)) do
	require("scripts.vendor.busted").run(file)
end
