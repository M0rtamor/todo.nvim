M = {}

local expand_path = function(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end

	return path
end

M.expand_path = expand_path

M.dir_exists = function(path)
	local expanded_path = expand_path(path)

	if vim.fn.isdirectory(expanded_path) == 0 then
		return false
	else
		return true
	end
end

M.get_buffer_from_file = function(path)
	local buf = vim.fn.bufnr(path, true)

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, path)
	end

	vim.bo[buf].swapfile = false
	vim.bo[buf].bufhidden = "wipe"

	return buf
end

local function calculate_position(position)
	local posx, posy = 0.5, 0.5

	-- Custom position
	if type(position) == "table" then
		posx, posy = position[1], position[2]
	end

	-- Keyword position
	if position == "center" then
		posx, posy = 0.5, 0.5
	elseif position == "topleft" then
		posx, posy = 0, 0
	elseif position == "topright" then
		posx, posy = 1, 0
	elseif position == "bottomleft" then
		posx, posy = 0, 1
	elseif position == "bottomright" then
		posx, posy = 1, 1
	end

	return posx, posy
end

M.win_config = function(opts)
	local width = math.floor(vim.o.columns * opts.window.size.width)
	local height = math.floor(vim.o.lines * opts.window.size.height)

	local posx, posy = calculate_position(opts.window.pos)

	local col = math.floor((vim.o.columns - width) * posx)
	local row = math.floor((vim.o.lines - height) * posy)

	return {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		border = opts.window.border,
	}
end

M.get_iso_dates_of_week = function(week, year)
	local jan4 = os.time{year=year, month=1, day=4}
	local jan4_weekday = tonumber(os.date("%u", jan4))

	local first_monday = jan4 - (jan4_weekday - 1) * 86400

	local target_monday = first_monday + (week - 1) * 7 * 86400
	local target_sunday = target_monday + 6 * 86400

	return target_monday, target_sunday
end

M.shift_week = function(week, year, shift)
	week = week + shift

	if week <= 0 then
		week = week + 52
		year = year - 1
	elseif week > 52 then
		week = week - 52
		year = year + 1
	end

	return week, year
end

M.save_buffer = function(buffer)
	if vim.api.nvim_get_option_value("modified", { buf = buffer }) then
		vim.api.nvim_buf_call(buffer, function()
			vim.cmd("write")
		end)
	end
end

return M
