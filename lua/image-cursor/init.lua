local config = require("image-cursor.config")
local formats = require("image-cursor.formats")
local parser = require("image-cursor.parser")
local placement = require("image-cursor.placement")
local state = require("image-cursor.state")

local M = {}

local opts = nil

local function update_preview_for_cursor()
	local win = vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(win) then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_get_cursor(win)[1]
	local line_text = vim.api.nvim_get_current_line()

	local raw_path = parser.extract_image_path(line_text)
	if raw_path == nil then
		if state.is_showing() and not state.is_showing_for(bufnr, cursor_line) then
			state.clear()
		end
		return
	end

	local absolute_path = parser.resolve_path(raw_path, bufnr)

	if vim.fn.filereadable(absolute_path) ~= 1 then
		if state.is_showing() then
			state.clear()
		end
		return
	end

	local cursor_row_in_window = vim.fn.winline()
	local cursor_col_in_window = vim.fn.wincol()
	local window_height = vim.api.nvim_win_get_height(win)
	local window_width = vim.api.nvim_win_get_width(win)

	local start_row, available_height = placement.choose_vertical_placement(
		cursor_row_in_window,
		window_height,
		opts.max_height_cells,
		opts.min_height_cells
	)

	if start_row == nil then
		if state.is_showing() then
			state.clear()
		end
		return
	end

	local max_width = math.min(opts.max_width_cells, window_width)
	local pixel_width, pixel_height = formats.dimensions(absolute_path)
	local width, height =
		placement.fit_to_cells(pixel_width, pixel_height, max_width, available_height, opts.cell_aspect)

	local placed_above = start_row < cursor_row_in_window
	if placed_above and height < available_height then
		start_row = cursor_row_in_window - height
	end

	local start_col = placement.choose_horizontal_placement(cursor_col_in_window, window_width, width)

	local image_opts = { row = start_row, col = start_col, width = width, height = height }

	if state.is_showing_for(bufnr, cursor_line) then
		pcall(vim.ui.img.set, state.get_image_id(), image_opts)
		return
	end

	-- if the state wasn't set properly, or the image isn't shown, or if we've moved to a different image/line
	state.clear()

	local ok, file_contents = pcall(vim.fn.readblob, absolute_path)
	if not ok or not file_contents then
		return
	end

	local set_ok, image_id = pcall(vim.ui.img.set, file_contents, image_opts)
	if set_ok then
		state.set_showing(image_id, bufnr, cursor_line)
	end
end

local function toggle_preview()
	if state.is_showing() then
		state.clear()
	else
		update_preview_for_cursor()
	end
end

local function attach_to_buffer(bufnr, augroup)
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = augroup,
		buffer = bufnr,
		callback = update_preview_for_cursor,
	})

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		group = augroup,
		buffer = bufnr,
		callback = function()
			state.clear()
		end,
	})
end

--- Init function for the plugin
--- To be called from plugin manager config.
--- for lazy.nvim:
---
--- {
--- "causality-enjoyer/image-cursor.nvim",
--- ft = { "markdown" }
--- opts = {},
--- }
---
--- @param user_opts table? available configs in config.lua
function M.setup(user_opts)
	opts = config.resolve(user_opts)

	local augroup = vim.api.nvim_create_augroup("ImageCursorPreview", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = opts.filetypes,
		callback = function(args)
			attach_to_buffer(args.buf, augroup)
		end,
	})

	if opts.keys ~= false and opts.keys.toggle then
		vim.keymap.set("n", opts.keys.toggle, toggle_preview, {
			desc = "Toggle cursor image preview",
		})
	end
end

M.formats = formats

return M
