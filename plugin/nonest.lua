local g, api, env, v = vim.g, vim.api, vim.env, vim.v
if g.loaded_nonest then
	return
end
g.loaded_nonest = true

env.EDITOR = vim.iter(v.argv):map(vim.fn.shellescape):join(' ')

vim.api.nvim_create_user_command('NonestEdit', function(args)
	local mods = args.mods

	vim.cmd(mods .. ' ' .. 'enew')
	vim.bo.buflisted = false

	vim.fn.jobstart(v.argv[1] .. ' ' .. vim.fn.shellescape('+let g:nonest_quitnow = 1') .. ' ' .. args.args, {
		term = true
	})
end, { nargs = 1 })

if not env.NVIM then
	return
end

local _, chan = pcall(vim.fn.sockconnect, 'pipe', env.NVIM, { rpc = true })

if not chan or chan == 0 then
	io.stderr:write('Nvim failed to connect to parent')
	vim.cmd("qall!")
end

---@param cmd string
local function send_cmd(cmd)
	vim.rpcnotify(chan, 'nvim_command', cmd)
end

api.nvim_create_autocmd('VimEnter', {
	callback = function()
		if vim.g.nonest_quitnow then
			send_cmd('edit ' .. vim.fn.fnameescape(api.nvim_buf_get_name(0)))
			vim.cmd('qall!')
			return
		end

		local winlayout = vim.fn.winlayout()
		local commands = require('nonest').winlayout_to_cmds(winlayout)

		send_cmd('tabnew')
		vim.iter(commands):each(send_cmd)

		local tabpagenr = vim.rpcrequest(chan, 'nvim_call_function', 'tabpagenr', {}) --[[@as integer]]
		vim.rpcnotify(chan, 'nvim_create_autocmd', 'TabClosed', {
			command = ([[if expand("<afile>") == %s | call rpcnotify(sockconnect('pipe', '%s', #{ rpc: v:true }), 'nvim_command', 'quitall!') | endif]])
				:format(tabpagenr, v.servername),
			once = true
		})
	end,
})
