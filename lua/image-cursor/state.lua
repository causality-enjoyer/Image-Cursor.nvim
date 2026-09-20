local M = {}

local current = { -- which current image we're tracking
	image_id = nil, -- vim.ui.img.set() provides an id for tracking, nill if nothing shown
	buffer_line = nil, -- 1-indexed buffer line the showm image belongs to
	bufnr = nil, -- which buffer number that line is in.
}

--- Returns true if there is an image on the screen
--- @return boolean
function M.is_showing()
	return current.image_id ~= nil
end

--- Returns true if repositioning an old image, else false
--- @param bufnr integer
--- @param buffer_line integer
--- @return boolean
function M.is_showing_for(bufnr, buffer_line)
	return current.image_id ~= nil and current.bufnr == bufnr and current.buffer_line == buffer_line
end

--- Get image id for current iamge
--- @return integer? image_id if an image exists, else returns nil
function M.get_image_id()
	return current.image_id
end

--- Set current variable to currently showing image
--- @param image_id integer
--- @param bufnr integer
--- @param buffer_line integer
function M.set_showing(image_id, bufnr, buffer_line)
	current.image_id = image_id
	current.bufnr = bufnr
	current.buffer_line = buffer_line
end

--- Clear current variable to flush the image
function M.clear()
	if current.image_id then
		pcall(vim.ui.img.del, current.image_id)
	end

	current.image_id = nil
	current.bufnr = nil
	current.buffer_line = nil
end

return M
