local nvim ---@type unnest.nvim

local abspath = vim.fs.abspath

local is_windows = vim.fn.has("win32") == 1

local function setup_child()
	nvim = require("unnest.nvim"):new(vim.fn.jobstart({ "nvim", "--headless", "--embed" }, {
		rpc = true,
		env = {
			-- The parent Nvim instance of this one is `nvim -l`, so we
			-- must unset $NVIM, otherwise it will hopelessly try to
			-- control the Nvim that run busted
			NVIM = "",
			-- Unset to make it use POSIX shell to run tests for faster startup
			-- time (on POSIX platforms). This doesn't affect Windows though.
			SHELL = "",
		},
	}))
end

---Convert any winid in winlayout into is a dictionary like
---{"name": bufname, "diff": &l:diff}
---@param winlayout vim.fn.winlayout.ret|integer
---@return table|integer
local function winlayout_handle_winid(winlayout)
	if type(winlayout) == "table" then
		return vim.tbl_map(function(w)
			return winlayout_handle_winid(w)
		end, winlayout)
	elseif type(winlayout) == "number" then
		return {
			name = abspath(nvim.nvim_buf_get_name(nvim.nvim_win_get_buf(winlayout))),
			diff = nvim.nvim_get_option_value("diff", { win = winlayout }) or nil,
		}
	else
		return winlayout
	end
end

describe("test plugin", function()
	before_each(function()
		nvim = require("unnest.nvim"):new(vim.fn.jobstart({ "nvim", "--headless", "--embed" }, {
			rpc = true,
			env = {
				-- The parent Nvim instance of this one is `nvim -l`, so we
				-- must unset $NVIM, otherwise it will hopelessly try to
				-- control the Nvim that run busted
				NVIM = "",
				-- Unset $SHELL to make tests use POSIX shell (sh) on POSIX
				-- systems. This doesn't affect Windows though.
				SHELL = "",
			},
		}))
	end)

	after_each(function()
		vim.fn.jobstop(nvim.chan)
	end)

	it("Test command :UnnestEdit", function()
		local win = nvim.nvim_get_current_win()
		nvim.nvim_command("UnnestEdit nvim Xtest/tmp/test_command.txt")
		vim.wait(200)

		-- job must have been closed
		local job = nvim.nvim_win_get_var(win, "unnest_chan")
		expect(nvim.nvim_exec_lua("return pcall(vim.fn.jobpid, ...)", { job })):same(false)

		-- Don't change window after running command
		expect(nvim.nvim_get_current_win()):same(1000)

		expect(nvim.nvim_get_option_value("buftype", {})):same("")

		local bufname = vim.fs.normalize(nvim.nvim_buf_get_name(0))
		expect(bufname):same_path("Xtest/tmp/test_command.txt")
	end)

	---@param cmd string
	---@param expected { winbuflayout: table, cwd?: string }
	local function test_winlayout(cmd, expected)
		local tab = nvim.nvim_get_current_tabpage()

		nvim.nvim_command(cmd)
		vim.wait(200)

		-- Must be in a new tab
		expect(nvim.nvim_get_current_tabpage()):Not():same(tab)

		-- the child Nvim hasn't been closed yet
		local child = nvim.nvim_tabpage_get_var(0, "unnest_socket") ---@type string
		expect(vim.fn.sockconnect("pipe", child)):Not():same(0)

		-- cwd must be the same as in child Nvim
		expect(nvim.nvim_call_function("getcwd", { -1, 0 })):same_path(expected.cwd or vim.fn.getcwd())

		-- winlayout must be the same as in child Nvim
		local winlayout = nvim.nvim_call_function("winlayout", {})
		expect(winlayout_handle_winid(winlayout)):same(expected.winbuflayout)

		-- Call :tabclose must close child Nvim, so sockconnect later must raise an
		-- error
		nvim.nvim_command("tabclose")
		vim.wait(100)

		expect(pcall(vim.fn.sockconnect, "pipe", child)):same(false)
	end

	for _, testcase in ipairs({
		{
			cmd = 'term nvim -d "README.md" "LICENSE" +"botright split .editorconfig" +"tcd Xtest"',
			expected = {
				winbuflayout = {
					"col",
					{
						{
							"row",
							{
								{ "leaf", { name = abspath("README.md"), diff = true } },
								{ "leaf", { name = abspath("LICENSE"), diff = true } },
							},
						},
						{ "leaf", { name = abspath(".editorconfig") } },
					},
				},
				cwd = "Xtest",
			},
		},
		{
			cmd = 'term nvim file1.txt +"split file2.txt" +"botright vsplit file3.txt" +"split file4.txt" +"botright vsplit file5.txt"',
			expected = {
				winbuflayout = {
					"row",
					{
						{
							"col",
							{
								{ "leaf", {
									name = abspath("file2.txt"),
								} },
								{ "leaf", {
									name = abspath("file1.txt"),
								} },
							},
						},
						{
							"col",
							{
								{ "leaf", {
									name = abspath("file4.txt"),
								} },
								{ "leaf", {
									name = abspath("file3.txt"),
								} },
							},
						},
						{ "leaf", {
							name = abspath("file5.txt"),
						} },
					},
				},
			},
		},
	}) do
		it("Test winlayout with command :" .. testcase.cmd, function()
			test_winlayout(testcase.cmd, testcase.expected)
		end)
	end
end)

describe("test restore insert mode", function()
	before_each(function()
		setup_child()
		nvim.nvim_command("term")
		if is_windows then
			--- Windows shell has slow startup time
			vim.wait(1000)
		end
	end)

	after_each(function()
		vim.fn.jobstop(nvim.chan)
	end)

	it("Should restore insert mode for terminal buffers", function()
		nvim.nvim_command("startinsert")
		nvim.nvim_feedkeys("nvim test.txt" .. vim.keycode("<CR>"), "m", true)
		vim.wait(2000)
		nvim.nvim_command("tabclose")

		expect(nvim.nvim_get_mode().mode):same("t")
	end)

	it("Should not restore insert mode if the previous window is not the original window", function()
		nvim.nvim_command("startinsert")
		nvim.nvim_feedkeys("nvim test.txt" .. vim.keycode("<CR>"), "m", true)
		vim.wait(2000)
		nvim.nvim_command("tabnew | tabprev | tabclose")

		expect(nvim.nvim_get_mode().mode):same("n")
	end)

	it("Should not restore insert mode if the previous window buffer changes", function()
		local win1 = nvim.nvim_get_current_win()

		nvim.nvim_command("vert term")

		local win2_buf = nvim.nvim_get_current_buf()

		nvim.nvim_set_current_win(win1)
		nvim.nvim_command("startinsert")
		nvim.nvim_feedkeys("nvim test.txt" .. vim.keycode("<CR>"), "m", true)
		vim.wait(2000)

		nvim.nvim_win_set_buf(win1, win2_buf)
		nvim.nvim_command("tabclose")

		expect(nvim.nvim_get_mode().mode):same("nt")
	end)

	it("Should not restore insert mode if the previous window buffer is not a terminal buffer", function()
		local win = nvim.nvim_get_current_win()
		local buf = nvim.nvim_create_buf(true, false)

		nvim.nvim_command("startinsert")
		nvim.nvim_feedkeys("nvim test.txt" .. vim.keycode("<CR>"), "m", true)
		vim.wait(2000)

		nvim.nvim_win_set_buf(win, buf)
		nvim.nvim_command("tabclose")

		expect(nvim.nvim_get_mode().mode):same("n")
	end)
end)
