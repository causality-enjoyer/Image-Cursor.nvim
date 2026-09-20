local M = {}

--- @param line string the raw line text
--- @return string? raw path the text between ( and ), or nil if this
function M.extract_image_path(line)
	local trimmed = vim.trim(line)

	if trimmed:sub(1, 2) ~= "![" then
		return nil
	end

	local alt_text_end = trimmed:find("%]%(")
	if not alt_text_end then
		return nil
	end

	local open_paren = alt_text_end + 1

	local close_paren = trimmed:find("%)([^%)]*)$")
	if not close_paren then
		return nil
	end

	return trimmed:sub(open_paren + 1, close_paren - 1)
end

return M
