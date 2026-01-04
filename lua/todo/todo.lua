local constants = require("todo.constants")
local utils = require("todo.utils")

M = {}

local DAY_IN_SECONDS = 86400

local win = nil
local buf = nil
local opened_week = 0
local opened_year = 0
local switch_week

-- @param week - string
-- @param year - string
local function get_weekly_filename(week, year)
	-- local iso_monday, iso_sunday = utils.get_iso_dates_of_week(week, year)
	-- local monday_string = os.date("%d.%m", iso_monday)
	-- local sunday_string = os.date("%d.%m", iso_sunday)
	--
	-- return monday_string .. "-" .. sunday_string .. ".md"
	week = tonumber(week)
	if week < 10 then
		return tostring(year) .. "-W0" .. tostring(week) .. ".md"
	end

	return tostring(year) .. "-W" .. tostring(week) .. ".md"
end

-- @param week - string
-- @param year - string
-- @param opts - table
local function get_weekly_path(week, year, opts)
	local expanded_path = utils.expand_path(opts.dirs.weekly)
	local weekly_filename = get_weekly_filename(week, year)

	return expanded_path .. "/" .. weekly_filename
end

-- @param buffer - Buffer id
-- @param mode - string
-- @param keymap - string
-- @param callback_func - function
-- @param param any
local function set_keymap(buffer, mode, keymap, callback_func, param)
	vim.api.nvim_buf_set_keymap(buffer, mode, keymap, "", {
		noremap = true,
		silent = true,
		callback = function()
			callback_func(param)
		end,
	})
end

-- @param todo_buf - Buffer id
-- @param opts - table
local function set_todo_window_keymaps(todo_buf, opts)
	local function close_window(_)
		utils.save_buffer(todo_buf)
		vim.api.nvim_win_close(0, true)
	end

	local function switch_window(increment)
		utils.save_buffer(todo_buf)
		switch_week(increment, opts)
	end

	set_keymap(todo_buf, "n", "q", close_window, _)
	set_keymap(todo_buf, "n", "H", switch_window, -1)
	set_keymap(todo_buf, "n", "L", switch_window, 1)
end

-- @param week - string
-- @param year - string
-- @param weekly_todo_path - string
local function init_weekly_file(week, year, weekly_todo_path)
	local iso_monday, _ = utils.get_iso_dates_of_week(week, year)

	local lines = {}
	local date_strings = {}

	for i = 1, 7 do
		table.insert(date_strings, os.date("%d.%m", iso_monday + (i-1)*DAY_IN_SECONDS))
	end

	local header = "# To Do Liste " .. date_strings[1] .. "-" .. date_strings[7] .. " KW" .. week

	table.insert(lines, header)
	table.insert(lines, "")

	for i = 1, 7 do
		table.insert(lines, "## " .. constants.day_names[i] .. " " .. date_strings[i])
		table.insert(lines, "")
	end

	vim.fn.writefile(lines, weekly_todo_path)
end

-- @param weekly_buf - Buffer id
-- @param window - window-ID
-- @param week - string
-- @param year - string
-- @param opts - table
local function open_week_in_window(weekly_buf, window, week, year, opts)
	local weekly_todo_path = get_weekly_path(week, year, opts)

	if vim.fn.filereadable(weekly_todo_path) == 0 then
		init_weekly_file(week, year, weekly_todo_path)
	end

	weekly_buf = utils.get_buffer_from_file(weekly_todo_path)

	if window ~= nil and vim.api.nvim_win_is_valid(window) then
		vim.api.nvim_win_set_buf(window, weekly_buf)
	else
		window = vim.api.nvim_open_win(weekly_buf, true, utils.win_config(opts))
	end

	return weekly_buf, window
end

-- @param relative - integer
-- @param opts - table
switch_week = function(relative, opts)
	opened_week, opened_year = utils.shift_week(opened_week, opened_year, relative)

	buf, win = open_week_in_window(buf, win, opened_week, opened_year, opts)

	set_todo_window_keymaps(buf, opts)
end

-- @param week string
-- @param year string
-- @param opts table
M.open_weekly = function(week, year, opts)
	if win ~= nil and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return
	end

	if not utils.dir_exists(opts.dirs.weekly) then
		print("Todo directory does no exist at " .. opts.dirs.weekly)
		return
	end

	opened_week, opened_year = week, year
	buf, win = open_week_in_window(buf, win, opened_week, opened_year, opts)

	set_todo_window_keymaps(buf, opts)
end

return M
