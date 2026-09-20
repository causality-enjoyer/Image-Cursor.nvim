local M = {}

M.default_cell_aspect = 0.5

--- Scale pixels to cell width/height for image rendering
---
--- Image proportions are preserved, we just need an estimate of
--- how many cells we need for rendering.
--- Set largest size that
--- (a) fits inside max_width_cells x max_height_cells
--- (b) keep the same aspect ratio
---
--- @param pixel_width integer? the image's actual width in pixels
--- @param pixel_height integer? the image's actual height in pixels
--- @param max_width_cells integer image canvas's largest width
--- @param max_height_cells integer image canvas's largest height
--- @param cell_aspect number? aspect ratio for a cell (width/height)
--- @return integer width_cells
--- @return integer height_cells
function M.fit_to_cells(pixel_width, pixel_height, max_width_cells, max_height_cells, cell_aspect)
	cell_aspect = cell_aspect or M.default_cell_aspect

	local have_real_dimension = pixel_width and pixel_height and pixel_width > 0 and pixel_height > 0

	if not have_real_dimension then
		return max_width_cells, max_height_cells
	end

	local pixel_aspect = pixel_width / pixel_height
	local cells_wide_per_cell_tall = pixel_aspect / cell_aspect

	-- if we were to use full width, and scale the height:
	local width_if_full_width = max_width_cells
	local height_if_full_width = math.floor(max_width_cells / cells_wide_per_cell_tall + 0.5)

	-- if we were to use full height, and scale the width:
	local width_if_full_height = math.floor(max_height_cells * cells_wide_per_cell_tall + 0.5)
	local height_if_full_height = max_height_cells

	local width, height -- the actual dimension that we'll render

	-- if no height overflow while full width, we use full width
	-- else, we use dimensions while full height
	if height_if_full_width <= max_height_cells then
		width, height = width_if_full_width, height_if_full_width
	else
		width, height = width_if_full_height, height_if_full_height
	end

	-- always default to usable width/height
	-- and if aspect ratio falls to low, always have at least
	-- 1 usable terminal cell as canvas width/height
	width = math.max(1, math.min(width, max_width_cells))
	height = math.max(1, math.min(height, max_height_cells))

	return width, height
end

--- Configure canvas position and image rendering's vertical placement
--- @param cursor_row_in_window integer 1-indexed row of cursor,
---   set by window's line (to consider line-wrapped)
--- @param window_height_rows integer total visible rows in the window
--- @param preferred_height_cells integer how tall we'd like the image to be if there's room
--- @param minimum_height_cells integer to check if top/bottom has too little space to render on
--- @return integer? start_row where to start imge rendering
--- @return integer available_height_cells
--- @return boolean placed_below true if placed below the cursor line
function M.choose_vertical_placement(
	cursor_row_in_window,
	window_height_rows,
	preferred_height_cells,
	minimum_height_cells
)
	local rows_below = window_height_rows - cursor_row_in_window
	local rows_above = cursor_row_in_window - 1

	local placed_below
	if rows_below >= minimum_height_cells and rows_below >= rows_above then
		placed_below = true
	elseif rows_above >= minimum_height_cells then
		placed_below = false
	else
		-- Neither side comfortably fits our minimum
		-- So we just choose the side that has more space for canvas.
		placed_below = rows_below >= rows_above
	end

	local available = placed_below and rows_below or rows_above

	-- If we don't find enough space for minimum requirement,
	-- we abort
	if available < minimum_height_cells then
		return nil, 0, placed_below
	end

	local height = math.min(preferred_height_cells, available)

	if height < 1 then
		return nil, 0, placed_below
	end

	local start_row
	if placed_below then
		start_row = cursor_row_in_window + 2
	else
		start_row = cursor_row_in_window - height
	end

	return start_row, height, placed_below
end

--- Configure canvas position and image rendering's vertical placement
--- @param cursor_col_in_window integer 1-indexed column of the cursor
--- within the window (to account for word wrapping)
--- @param window_width_cols integer total width of the window in columns
--- @param image_width_cells integer number of cells for canvas horizontally
--- @return integer start_col
function M.choose_horizontal_placement(cursor_col_in_window, window_width_cols, image_width_cells)
	local col = cursor_col_in_window

	local rightmost_column_used = col + image_width_cells - 1
	if rightmost_column_used > window_width_cols then
		col = window_width_cols - image_width_cells + 1
	end

	if col < 1 then
		col = 1
	end

	return col
end

return M
