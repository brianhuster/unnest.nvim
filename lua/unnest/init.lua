local M = {}

local api = vim.api

--- :UnnestEdit {cmd}
---@param cmd vim.api.keyset.create_user_command.command_args
function M.ex_edit(cmd)
	vim.cmd.enew()
	local child_chan = vim.fn.jobstart(vim.fn.expandcmd(cmd.args), {
		term = true,
		env = {
			NVIM_UNNEST_NOWAIT = 1,
		},
	})
	if vim.v.testing == 1 then
		vim.w.unnest_chan = child_chan
	end
	local buf = api.nvim_get_current_buf()
	api.nvim_create_autocmd("BufHidden", {
		buffer = buf,
		callback = function()
			vim.fn.jobstop(child_chan)
			vim.schedule(function()
				api.nvim_buf_delete(buf, { force = true })
			end)
		end,
	})
	vim.cmd.startinsert()
end

---@param winlayout vim.fn.winlayout.ret
---@return string|{ method: string, args: any[] }[]
function M.winlayout_to_cmds(winlayout)
	local commands = {} ---@type string[]
	local first_win = true -- first window in a row/col
	local first_win_in_tab = true -- first window in a tab

	---@param winid integer
	---@param cmd string
	---@param mod? string
	local function get_cmds_for_win(winid, cmd, mod)
		local buf = api.nvim_win_get_buf(winid)
		local bufname = api.nvim_buf_get_name(buf)
		if bufname == "" then
			cmd = cmd .. " | enew"
		end
		table.insert(commands, ("%s %s %s"):format(mod or "", cmd, vim.fn.fnameescape(bufname)))
		if vim.wo[winid].diff then
			table.insert(commands, "diffthis")
		end
		-- Sometimes `nvim +Man!` cannot recognize the name of the man page.
		-- And some shells like fish may provide `man` built-in with some man
		-- pages unrecognized by standard `man` executable. In these cases,
		-- Nvim may still recognize the name of the manpage (e.g `man://help`),
		-- but `:edit man://help` will still fail. I considered sending a PR to
		-- Nvim to invoke `man` from shell, but I think that could be a
		-- breaking change, because the man page the shell may have the same
		-- name but different content from the one that `man` executable
		-- provides (as the result, it could be a breaking change for those who
		-- use `man` for C programming for example).
		if bufname:sub(1, 6) == "man://" then
			table.insert(commands, "setlocal modifiable")
			table.insert(commands, {
				method = "nvim_buf_set_lines",
				args = { 0, 0, -1, false, api.nvim_buf_get_lines(buf, 0, -1, false) },
			})
			table.insert(commands, "setlocal nomodifiable")
		end
		first_win = false
		first_win_in_tab = false
	end

	---@param layout vim.fn.winlayout.ret
	---@param last_split? 'vsplit'|'split'
	local function process_winlayout(layout, last_split)
		local type = layout[1]

		---@param data vim.fn.winlayout.ret[]
		---@param split_type "vsplit"|"split"
		local function process_splits(data, split_type)
			process_winlayout(data[1], split_type)

			for i = 2, #data do
				local winid = nil
				if data[i][1] == "leaf" then
					winid = data[i][2] --[[@as integer]]
					get_cmds_for_win(winid, split_type, first_win and "botright" or "belowright")
				else
					process_winlayout(data[i], split_type)
				end

				if i == #data then
					first_win = true
				end
			end
		end

		if type == "leaf" then
			local winid = layout[2] --[[@as integer]]
			local cmd = first_win_in_tab and "edit" or (last_split == "vsplit" and "split" or "vsplit")
			get_cmds_for_win(winid --[[@as integer]], cmd, "botright")
		elseif type == "col" then
			process_splits(layout[2] --[[@as vim.fn.winlayout.ret[] ]], "split")
		elseif type == "row" then
			process_splits(layout[2] --[[@as vim.fn.winlayout.ret[] ]], "vsplit")
		end
	end

	process_winlayout(winlayout)
	return commands
end

return M
