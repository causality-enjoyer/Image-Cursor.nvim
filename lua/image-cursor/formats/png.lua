--- Refer to https://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html
--- for file formatting, as I've followed their specification.
--- File Structure:
--- PNG file signature: 137 80 78 71 13 10 26 10 (8 bytes)
--- in ASCII            <%> P  N  G  \r \n <> \n
--- Chunk length (4 byte)
--- Chunk Type (4 byte)
--- Chunk Data (possibly 0 bytes)
---

local M = {}

local PNG_SIGNATURE = "\137PNG\r\n\26\n"
local HEADER_BYTES_NEEDED = 24

--- Combine four bytes into one big-endian unsigned 32-bit integer
--- @param byte1 integer MSB
--- @param byte2 integer
--- @param byte3 integer
--- @param byte4 integer LSB
--- @return integer
local function bytes_to_u32_big_endian(byte1, byte2, byte3, byte4)
	return (byte1 * 0x1000000) + (byte2 * 0x10000) + (byte3 * 0x100) + byte4
end

--- Read pixel width and height of a PNG file
--- @param path string absolute path to the file on disk
--- @return integer? width in pixels
--- @return integer? height in pixels
function M.dimensions(path)
	local file = io.open(path, "rb") -- read in binary mode
	if not file then
		return
	end

	local header = file:read(HEADER_BYTES_NEEDED)
	file:close()

	if not header or #header < HEADER_BYTES_NEEDED then
		return nil
	end

	if header:sub(1, 8) ~= PNG_SIGNATURE then
		return nil
	end

	if header:sub(13, 16) ~= "IHDR" then
		return nil
	end

	local w1, w2, w3, w4 = header:byte(17, 20)
	local h1, h2, h3, h4 = header:byte(21, 24)

	if not (w1 and w2 and w3 and w4 and h1 and h2 and h3 and h4) then
		return nil
	end

	local width = bytes_to_u32_big_endian(w1, w2, w3, w4)
	local height = bytes_to_u32_big_endian(h1, h2, h3, h4)

	return width, height
end

return M
