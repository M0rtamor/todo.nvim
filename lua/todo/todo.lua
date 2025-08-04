local constants = require("todo.constants")
local utils = require("todo.utils")

M = {}

local win = nil
local buf = nil
local opened_week = 0
local opened_year = 0
local switch_week

local function get_weekly_filename(week, year)
	-- local iso_monday, iso_sunday = utils.get_iso_dates_of_week(week, year)
	-- local monday_string = os.date("%d.%m", iso_monday)
	-- local sunday_string = os.date("%d.%m", iso_sunday)
	--
	-- return monday_string .. "-" .. sunday_string .. ".md"
	if tonumber(week) < 10 then
		return tostring(year) .. "-W0" .. tostring(week) .. ".md"
	end

	return tostring(year) .. "-W" .. tostring(week) .. ".md"
end


local function get_weekly_path(week, year, opts)
	local expanded_path = utils.expand_path(opts.dirs.weekly)
	local weekly_filename = get_weekly_filename(week, year)

	return expanded_path .. "/" .. weekly_filename
end

local function set_todo_window_keymaps(todo_buf, opts)
	vim.api.nvim_buf_set_keymap(todo_buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = todo_buf }) then
				vim.api.nvim_buf_call(todo_buf, function()
				  vim.cmd("write")
				end)
				vim.api.nvim_win_close(0, true)
				win = nil
				return
			end
			vim.api.nvim_win_close(0, true)
			win = nil
		end,
	})
	vim.api.nvim_buf_set_keymap(todo_buf, "n", "H", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = todo_buf }) then
				vim.api.nvim_buf_call(todo_buf, function()
				  vim.cmd("write")
				end)
			end
			switch_week(-1, opts)
		end,
	})
	vim.api.nvim_buf_set_keymap(todo_buf, "n", "L", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = todo_buf }) then
				vim.api.nvim_buf_call(todo_buf, function()
				  vim.cmd("write")
				end)
			end
			switch_week(1, opts)
		end
	})
end

local function init_weekly_file(week, year, weekly_todo_path)
	local iso_monday, _ = utils.get_iso_dates_of_week(week, year)

	local lines = {}
	local day_strings = {}

	for i = 1, 7 do
		table.insert(day_strings, os.date("%d.%m", iso_monday + (i-1)*86400))
	end

	local header = "# To Do Liste " .. day_strings[1] .. "-" .. day_strings[7]

	table.insert(lines, header)
	table.insert(lines, "")

	for i = 1, 7 do
		table.insert(lines, "## " .. constants.day_names[i] .. " " .. day_strings[i])
		table.insert(lines, "")
	end

	vim.fn.writefile(lines, weekly_todo_path)
end

local function open_week_in_window(weekly_buf, window, week, year, opts)
	local weekly_todo_path = get_weekly_path(week, year, opts)

	if vim.fn.filereadable(weekly_todo_path) == 0 then
		init_weekly_file(week, year, weekly_todo_path)
	end

	if window ~= nil and vim.api.nvim_win_is_valid(window) then
		vim.api.nvim_buf_delete(weekly_buf, { force = true })
		weekly_buf = nil
		weekly_buf = utils.get_buffer_from_file(weekly_todo_path)
		if not vim.api.nvim_win_is_valid(window) then
			window = vim.api.nvim_open_win(weekly_buf, true, utils.win_config(opts))
		else
			vim.api.nvim_win_set_buf(window, weekly_buf)
		end
	else
		if weekly_buf ~= nil then
			vim.api.nvim_buf_delete(weekly_buf, { force = true })
			weekly_buf = nil
		end
		weekly_buf = utils.get_buffer_from_file(weekly_todo_path)
		window = vim.api.nvim_open_win(weekly_buf, true, utils.win_config(opts))
	end

	return weekly_buf, window
end

switch_week = function(relative, opts)
	opened_week, opened_year = utils.shift_week(opened_week, opened_year, relative)

	buf, win = open_week_in_window(buf, win, opened_week, opened_year, opts)

	set_todo_window_keymaps(buf, opts)
end

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
