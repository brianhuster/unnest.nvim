-- MIT License
--
-- Copyright (c) 2020 TJ DeVries
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local dirname = vim.fs.dirname

local function get_trace(_, level, msg)
	local function trimTrace(info)
		local index = info.traceback:find("\n%s*%[C]")
		info.traceback = info.traceback:sub(1, index)
		return info
	end
	level = level or 3

	local thisdir = dirname(debug.getinfo(1, "Sl").source)

	---@class debuginfo
	---@field traceback string
	---@field message string
	local info = debug.getinfo(level, "Sl")
	while
		info.what == "C"
		or info.short_src:match("luassert[/\\].*%.lua$")
		or (info.source:sub(1, 1) == "@" and thisdir == dirname(info.source))
	do
		level = level + 1
		info = debug.getinfo(level, "Sl")
	end

	info.traceback = debug.traceback("", level)
	info.message = msg

	local file = false
	return file and file.getTrace(file.name, info) or trimTrace(info)
end

-- We are shadowing print so people can reliably print messages
print = function(...)
	for _, v in ipairs({ ... }) do
		io.stdout:write(tostring(v))
		io.stdout:write("\t")
	end

	io.stdout:write("\r\n")
end

local mod = {}

local results = {}
local current_description = {}
local current_before_each = {}
local current_after_each = {}

local add_description = function(desc)
	table.insert(current_description, desc)

	return vim.deepcopy(current_description)
end

local pop_description = function()
	current_description[#current_description] = nil
end

local add_new_each = function()
	current_before_each[#current_description] = {}
	current_after_each[#current_description] = {}
end

local clear_last_each = function()
	current_before_each[#current_description] = nil
	current_after_each[#current_description] = nil
end

local call_inner = function(desc, func)
	local desc_stack = add_description(desc)
	add_new_each()
	local ok, msg = xpcall(func, function(msg)
		local trace = get_trace(nil, 3, msg)
		return trace.message .. "\n" .. trace.traceback
	end)
	clear_last_each()
	pop_description()

	return ok, msg, desc_stack
end

local color_string = function(color, str)
	local color_table = {
		green = 32,
		red = 31,
	}
	return string.format("%s[%sm%s%s[%sm", string.char(27), color_table[color] or 0, str, string.char(27), 0)
end

local success = color_string("green", "Success")
local fail = color_string("red", "Fail")

local header = string.rep("=", 40)

local format_results = function(res)
	print("")
	print(color_string("green", "Success: "), #res.pass)
	print(color_string("red", "Failed : "), #res.fail)
	print(color_string("red", "Errors : "), #res.errs)
	print(header)
end

mod.describe = function(desc, func)
	results.pass = results.pass or {}
	results.fail = results.fail or {}
	results.errs = results.errs or {}

	describe = mod.inner_describe
	local ok, msg, desc_stack = call_inner(desc, func)
	describe = mod.describe

	if not ok then
		table.insert(results.errs, {
			descriptions = desc_stack,
			msg = msg,
		})
	end
end

mod.inner_describe = function(desc, func)
	local ok, msg, desc_stack = call_inner(desc, func)

	if not ok then
		table.insert(results.errs, {
			descriptions = desc_stack,
			msg = msg,
		})
	end
end

mod.before_each = function(fn)
	table.insert(current_before_each[#current_description], fn)
end

mod.after_each = function(fn)
	table.insert(current_after_each[#current_description], fn)
end

local indent = function(msg, spaces)
	spaces = spaces or 4

	local prefix = string.rep(" ", spaces)
	return prefix .. msg:gsub("\n", "\n" .. prefix)
end

local run_each = function(tbl)
	for _, v in ipairs(tbl) do
		for _, w in ipairs(v) do
			if type(w) == "function" then
				w()
			end
		end
	end
end

mod.it = function(desc, func)
	run_each(current_before_each)
	local ok, msg, desc_stack = call_inner(desc, func)
	run_each(current_after_each)

	local test_result = {
		descriptions = desc_stack,
		msg = nil,
	}

	local to_insert
	if not ok then
		to_insert = results.fail
		test_result.msg = msg

		print(fail, "||", table.concat(test_result.descriptions, " "))
		print(indent(msg, 12))
	else
		to_insert = results.pass
		print(success, "||", table.concat(test_result.descriptions, " "))
	end

	table.insert(to_insert, test_result)
end

describe = mod.describe
it = mod.it
before_each = mod.before_each
after_each = mod.after_each
assert = require("luassert")

---@param file string
mod.run = function(file)
	file = vim.fs.normalize(file)

	print("\n" .. header)
	print("Testing: ", file)

	local loaded, msg = loadfile(file)

	if not loaded then
		print(header)
		print("FAILED TO LOAD FILE")
		print(color_string("red", msg))
		print(header)
		os.exit(2)
	end

	coroutine.wrap(function()
		loaded()

		-- If nothing runs (empty file without top level describe)
		if not results.pass then
			print("No tests found in file " .. file)
			os.exit(1)
		end

		format_results(results)

		if #results.errs ~= 0 then
			print("We had an unexpected error: ", vim.inspect(results.errs), vim.inspect(results))
			os.exit(2)
		elseif #results.fail > 0 then
			print("Tests Failed. Exit: 1")

			os.exit(1)
		end
	end)()
end

return mod
