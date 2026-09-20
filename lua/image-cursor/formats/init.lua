local M = {}

local READERS = {
	png = require("image-cursor.formats.png"),
}

--- @param path string
--- @return string | nil
--- extension, lowercase, without the leading dot
local function get_extension(path)
	local ext = path:match("%.([%a%d]+)$")

	if not ext then
		return nil
	end
	return ext:lower()
end

--- Try to read an image file's pixel dimensions, regardless of format
--- as long as a reader is registered for its extension
---
--- Returns nil, if the extension is not recognized
--- or if the parser couldn't parse the file
--- or if extension doesn't match the file contents.
--- @param path string absolute path to the image file
--- @return integer? width
--- @return integer? height
function M.dimensions(path)
	local ext = get_extension(path)
	if not ext then
		return nil
	end

	local reader = READERS[ext]
	if not reader then
		return nil
	end

	return reader.dimensions(path)
end

--- Returns true if there is a file-reader for this file extension.
--- Currently supports only PNG format.
--- @param path string
--- @return boolean
function M.is_supported(path)
	local ext = get_extension(path)
	return ext ~= nil and READERS[ext] ~= nil
end

return M
