vim.cmd([[
	set runtimepath^=.
	helptags doc
]])

local exit_code = 0

---@param bufnr integer
---@return string[]
local function get_help_taglinks(bufnr)
	local query = vim.treesitter.query.parse(
		"vimdoc",
		[[
		(taglink text: (word) @tag_text)
	]]
	)

	local parser, err = vim.treesitter.get_parser(bufnr, "vimdoc")
	if not parser then
		error(err)
	end
	local tree = parser:parse()[1]
	local taglinks = {}

	for _, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
		local text = vim.treesitter.get_node_text(node, bufnr)
		table.insert(taglinks, text)
	end

	return taglinks
end

---@param name string
local function lint_helpfile(name)
	vim.cmd.edit(name)
	local taglinks = get_help_taglinks(0)
	for _, taglink in ipairs(taglinks) do
		local completions = vim.fn.getcompletion(taglink, "help")
		if not vim.list_contains(completions, taglink) then
			exit_code = 1
			io.stderr:write(string.format("Tag |%s| invalid\n", taglink))
		end
	end
end

for _, helpfile in ipairs(vim.fn.globpath(".", "doc/*.txt", true, true)) do
	io.stderr:write(string.format("\nLinting %s\n", helpfile))
	lint_helpfile(helpfile)
	os.exit(exit_code)
end
