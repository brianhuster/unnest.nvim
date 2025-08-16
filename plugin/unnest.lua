local g, api, env, v = vim.g, vim.api, vim.env, vim.v
if g.loaded_unnest then
	return
end
g.loaded_unnest = true

env.VISUAL = v.progpath
env.EDITOR = v.progpath

api.nvim_create_user_command("UnnestEdit", function(cmd)
	require("unnest").ex_edit(cmd)
end, {
	nargs = 1,
	desc = "Run {cmd} in a terminal buffer in curent window. If it opens a Nvim instance with a file path, the file will be opened in the parent Nvim instance, and the child Nvim instance will be closed right away.",
	complete = "shellcmdline",
})

if not env.NVIM then
	return
end

local _, parent_chan = pcall(vim.fn.sockconnect, "pipe", env.NVIM, { rpc = true })

if not parent_chan or parent_chan == 0 then
	io.stderr:write("Nvim failed to connect to parent")
	vim.cmd("qall!")
end

local parent_has_unnest = vim.rpcrequest(parent_chan, "nvim_exec_lua", "return pcall(require, 'unnest')", {})

--- Don't load this plugin if the parent Nvim doesn't have this plugin.
if not parent_has_unnest then
	vim.fn.chanclose(parent_chan)
	return
end

---@param cmd string
local function send_cmd(cmd)
	vim.rpcnotify(parent_chan, "nvim_command", cmd)
end

api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if env.NVIM_UNNEST_NOWAIT then
			send_cmd("edit " .. vim.fn.fnameescape(api.nvim_buf_get_name(0)))
			vim.cmd("qall!")
			return
		end

		local winlayout = vim.fn.winlayout()
		local commands = require("unnest").winlayout_to_cmds(winlayout)

		send_cmd("tabnew")
		vim.iter(commands):each(send_cmd)

		-- New tabpage should also stimulate cwd of nested Nvim
		send_cmd("tcd " .. vim.fn.fnameescape(vim.fn.getcwd(-1, 0)))

		if vim.v.testing == 1 then
			vim.rpcnotify(parent_chan, "nvim_tabpage_set_var", 0, "unnest_socket", v.servername)
		end

		local tabpagenr = vim.rpcrequest(parent_chan, "nvim_call_function", "tabpagenr", {}) --[[@as integer]]
		vim.rpcnotify(parent_chan, "nvim_create_autocmd", "TabClosed", {
			command = ([[if expand("<afile>") == %s | call rpcnotify(sockconnect('pipe', '%s', #{ rpc: v:true }), 'nvim_command', 'quitall!') | endif]]):format(
				tabpagenr,
				v.servername
			),
			once = true,
		})
	end,
})
