local g, api, env, v = vim.g, vim.api, vim.env, vim.v
if g.loaded_unnest then
	return
end
g.loaded_unnest = true

env.EDITOR = vim.iter(v.argv):map(vim.fn.shellescape):join(' ')

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
		local winlayout = vim.fn.winlayout()
		local commands = require('unnest').winlayout_to_cmds(winlayout)

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
