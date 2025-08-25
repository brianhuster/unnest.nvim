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

local parent = require("unnest.nvim"):new(parent_chan)
local parent_has_unnest = parent.nvim_exec_lua("return pcall(require, 'unnest')", {})

--- Don't load this plugin if the parent Nvim doesn't have this plugin.
if not parent_has_unnest then
	vim.fn.chanclose(parent_chan)
	return
end

api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if env.NVIM_UNNEST_NOWAIT then
			parent.rpcnotify.nvim_cmd({
				cmd = "edit",
				args = { api.nvim_buf_get_name(0) },
			}, {})
			vim.cmd("qall!")
			return
		end

		local win_id = parent.nvim_get_current_win()
		local buf_id = parent.nvim_win_get_buf(win_id)
		local buf_type = parent.nvim_get_option_value("buftype", { buf = buf_id })
		local mode = parent.nvim_get_mode().mode

		local winlayout = vim.fn.winlayout()
		local commands = require("unnest").winlayout_to_cmds(winlayout)

		parent.rpcnotify.nvim_command("tabnew")
		vim.iter(commands):each(parent.rpcnotify.nvim_command)

		-- New tabpage should also stimulate cwd of nested Nvim
		parent.rpcnotify.nvim_command("tcd " .. vim.fn.fnameescape(vim.fn.getcwd(-1, 0)))

		if vim.v.testing == 1 then
			parent.rpcnotify.nvim_tabpage_set_var(0, "unnest_socket", v.servername)
		end

		local tabpagenr = parent.nvim_call_function("tabpagenr", {}) --[[@as integer]]
		parent.rpcnotify.nvim_create_autocmd("TabClosed", {
			command = ([[if expand("<afile>") == %s | call rpcnotify(sockconnect('pipe', '%s', #{ rpc: v:true }), 'nvim_command', 'quitall!') | endif]]):format(
				tabpagenr,
				v.servername
			),
			once = true,
		})

		-- Re-enable insert mode if the last window in the parent contained a
		-- terminal buffer and we were in terminal insert mode, but only if the new
		-- window (after closing the tab) is that same window.
		if buf_type == "terminal" and mode == "t" then
			parent.rpcnotify.nvim_create_autocmd("TabClosed", {
				command = ([[if nvim_get_current_win() == %s && nvim_get_current_buf() == %s && &buftype == 'terminal' | startinsert | endif]]):format(
					win_id,
					buf_id
				),
				once = true,
			})
		end
	end,
})
