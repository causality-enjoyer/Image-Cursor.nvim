-- Default settings, and merging whatever the user passes into the setup() method

local M = {}

M.defaults = {
	-- filetypes to watch for plugin usage.
	filetypes = { "markdown" },

	-- maximum size of preview, in terminal cell units.
	max_width_cells = 40,
	max_height_cells = 20,

	-- minimum height for rendering the image
	min_height_cells = 6,

	-- terminal cell have 1:2 ratio, so for correction of image rendering
	-- we scale down by cell_aspect
	cell_aspect = nil,

	-- keymap to manually toggle the preview on/off for current line
	keys = {
		toggle = "<leader>ii",
	},
}

--- Merge user-supplied options over the defaults
--- @param user_opts table? Parameters set by the user
--- @return table merged options

function M.resolve(user_opts)
	return vim.tbl_deep_extend("force", {}, M.defaults, user_opts or {})
end

return M
