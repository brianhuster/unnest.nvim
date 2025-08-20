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

for _, file in ipairs(vim.fn.globpath(cwd, "spec/**/*_spec.lua", true, true)) do
	require("scripts.vendor.busted").run(file)
end
