local M = {}

--- @param line string the raw line text
--- @return string? raw path the text between ( and ), or nil if this
function M.extract_image_path(line)
	local trimmed = vim.trim(line)

	-- Remove bullet prefix: "- ", "* ", "-", "*"
	local content = trimmed:match("^[%-%*]%s*(.+)$") or trimmed

	-- image syntax would start from ![
	if content:sub(1, 2) ~= "![" then
		return nil
	end

	-- alt text end, and begin iamge path at ](
	local alt_text_end = content:find("]%(", 1, false)
	if not alt_text_end then
		return nil
	end

	local open_paren = alt_text_end + 1 -- index of "("

	-- index of )
	local close_paren = content:find("%)%s*$")
	if not close_paren then
		return nil
	end

	return content:sub(open_paren + 1, close_paren - 1)
end

--- Resolve the path of the file into absolute filesystem path
--- @param raw_path string the path as written inside ![]( )
--- @param bufnr integer the buffer the markdown file is in, used to
---   resolve relative paths against that file's directory
--- @return string absolute_path
function M.resolve_path(raw_path, bufnr)
	local path = raw_path:gsub("%%20", " ") -- incase the user has file names with spaces inside them.

	if path:sub(1, 1) == "/" or path:sub(1, 1) == "~" then
		return vim.fn.expand(path)
	end

	local buffer_directory = vim.fn.expand("#" .. bufnr .. ":p:h")
	return buffer_directory .. "/" .. path
end

return M
