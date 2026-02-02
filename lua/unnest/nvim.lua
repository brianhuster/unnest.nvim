local nvim = {}

---@class vim.Api
vim.api = vim.api

---@class unnest.NvimApi: vim.Api
---@field nvim_exec_lua fun(code: string, fargs: any[]): any|vim.NIL

---@class unnest.Nvim: unnest.NvimApi
---@field chan integer
---@field rpcnotify unnest.NvimApi

---@param chan integer
---@return unnest.Nvim
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
