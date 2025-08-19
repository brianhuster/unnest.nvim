local nvim = {}

---@class unnest.nvim_api
---@field nvim_exec_lua fun(code: string, fargs: any[]): any|vim.NIL
vim.api = vim.api

---@class unnest.nvim: unnest.nvim_api
---@field chan integer
---@field rpcnotify unnest.nvim_api

---@param chan integer
---@return unnest.nvim
function nvim:new(chan)
	local child = setmetatable({}, {
		__index = function(_, key)
			if key == "rpcnotify" then
				return setmetatable({}, {
					__index = function(_, method)
						return function(...)
							return vim.rpcnotify(chan, method, ...)
						end
					end,
				})
			end
			return function(...)
				return vim.rpcrequest(chan, key, ...)
			end
		end,
	})
	child.chan = chan
	return child
end

return nvim
