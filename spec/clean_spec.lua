describe("Test with clean Nvim", function()
	local nvim ---@type unnest.nvim

	before_each(function()
		nvim = require("unnest.nvim"):new(vim.fn.jobstart({ "nvim", "--clean", "--headless", "--embed" }, {
			rpc = true,
		}))
	end)

	it("Should do nothing after opening a Nvim in terminal buffer", function()
		local win = nvim.nvim_get_current_win()
		nvim.nvim_command("term nvim test_clean.txt")
		vim.wait(500)

		expect(nvim.nvim_get_current_win()):same(win)
		expect(nvim.nvim_get_option_value("buftype", {})):same("terminal")
	end)

	after_each(function()
		vim.fn.jobstop(nvim.chan)
	end)
end)
