local todo = require("todo.todo")

local M = {}

local default_opts = {
	dirs = {
		weekly = "~/Todo/Weekly",
		dump = "~/Todo/Dump",
		global = "~/Todo",
	},
	window = {
		border = "rounded",
		pos = "center",
		size = {
			height = "0.8",
			width = "0.8",
		},
	},
	files = {
		weekly_header = "",
		date_format = "",
		day_names = "",
	},
}

local function setup_user_commands(opts)
	vim.api.nvim_create_user_command("Todo", function(arg)
		if arg.fargs[1] == "weekly" then
			local week = os.date("%V")
			local year = os.date("%Y")
			todo.open_weekly(week, year, opts)
		end
	end, { nargs = 1, })
end

M.setup = function(opts)
	opts = vim.tbl_deep_extend("force", default_opts, opts)
	setup_user_commands(opts)
end

return M
