-- stylua: ignore

local KEYS_label = {
	"j", "f", "d", "k", "l", "h", "g", "a", "s", "o", "i", "e", "u", "n", "c", "m", "r", "p", "b", "t", "w", "v", "x",
	"y", "q", "z",
	"I", "J", "L", "H", "A", "B", "Y", "D", "E", "F", "G", "Q", "R", "T",
	"U", "V", "W", "X", "Z", "C", "K", "M", "N", "O", "P", "S",
}

local INPUT_KEY = {
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",
	"X", "Y", "Z",

	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
	"o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2"
, "3", "4", "5", "6", "7", "8", "9", "-", "_", ".", "<Esc>", "<Space>", "<Enter>", "<Backspace>"
}

local INPUT_CANDS = {
	{ on = "A" }, { on = "B" }, { on = "C" }, { on = "D" }, { on = "E" },
	{ on = "F" }, { on = "G" }, { on = "H" }, { on = "I" }, { on = "J" },
	{ on = "K" }, { on = "L" }, { on = "M" }, { on = "N" }, { on = "O" },
	{ on = "P" }, { on = "Q" }, { on = "R" }, { on = "S" }, { on = "T" },
	{ on = "U" }, { on = "V" }, { on = "W" }, { on = "X" }, { on = "Y" },
	{ on = "Z" },

	{ on = "a" }, { on = "b" }, { on = "c" }, { on = "d" }, { on = "e" },
	{ on = "f" }, { on = "g" }, { on = "h" }, { on = "i" }, { on = "j" },
	{ on = "k" }, { on = "l" }, { on = "m" }, { on = "n" }, { on = "o" },
	{ on = "p" }, { on = "q" }, { on = "r" }, { on = "s" }, { on = "t" },
	{ on = "u" }, { on = "v" }, { on = "w" }, { on = "x" }, { on = "y" },
	{ on = "z" }, { on = "0" }, { on = "1" }, { on = "2" }, { on = "3" },
	{ on = "4" }, { on = "5" }, { on = "6" }, { on = "7" }, { on = "8" },
	{ on = "9" }, { on = "-" }, { on = "_" }, { on = "." }, { on = "<Esc>" },
	{ on = "<Space>" }, { on = "<Enter>" }, { on = "<Backspace>" }
}


local set_re_match = ya.sync(function(state, re_match)
	state.re_match = re_match
end)

local get_re_match_state = ya.sync(function(state)
	return state.re_match
end)

local insert_next_char = ya.sync(function(state, next_char)
	if next_char == nil then
		return
	end

	if next_char:byte() > 127 then
		if state.mapdata and state.mapdata[next_char] then
			for i = 1, #state.mapdata[next_char] do
				state.next_char[state.mapdata[next_char][i]] = ""
			end
		end
	else
		state.next_char[next_char] = ""
	end
end)

local check_is_match_ch_char = function(target_char, ch_char_initial)
	for i = 1, #ch_char_initial do
		if target_char == ch_char_initial[i] then
			return true
		end
	end
	return false
end

local function get_match_position(state, name, find_str)
	if find_str == "" or find_str == nil then
		return nil, nil
	end

	local startPos, endPos = {}, {}
	local startp, endp
	local convert_name = ""
	name = string.lower(name)
	local is_valid_ch_char = false
	local is_ch_char = false
	local is_match_char = false

	-- input mode
	if not get_re_match_state() then
		local i = 1
		local j = 1
		local real_start_pos = 0
		local real_end_pos = 0
		local real_index = 1
		find_str = string.lower(find_str)
		local wide_char_name = {}
		local wide_char_match_begin = 0
		local index_wide_char
		local ch_char_initial
		for utf8_char in string.gmatch(name, "[%z\1-\127\194-\244][\128-\191]*") do
			table.insert(wide_char_name, utf8_char)
		end
		-- wide_char_name is the array of the multi-width character
		-- after combining the elements of the array
		-- so the real_index should be added 3 (Chinese)
		while j <= #wide_char_name do
			index_wide_char = wide_char_name[j]
			ch_char_initial = state.mapdata[index_wide_char]

			is_ch_char = (index_wide_char:byte() > 127)
			is_valid_ch_char = (is_ch_char and ch_char_initial)

			if is_valid_ch_char then
				is_match_char = check_is_match_ch_char(find_str:sub(i, i), ch_char_initial)
			else
				is_match_char = find_str:sub(i, i) == index_wide_char
			end

			-- match the first char
			if real_start_pos == 0 and is_match_char then
				real_start_pos = real_index
				wide_char_match_begin = j
			end

			if real_start_pos ~= 0 and is_match_char then
				-- match the end char
				if i == #find_str then
					real_end_pos = real_index + (is_ch_char and 2 or 0)
					table.insert(startPos, real_start_pos)
					table.insert(endPos, real_end_pos)
					insert_next_char(wide_char_name[j + 1])
					i = 1
					wide_char_match_begin = 0
					real_end_pos = 0
					real_start_pos = 0
				else
					i = i + 1
				end
				-- match failed, reset match begin index to the next char
				-- of the first match char
				real_index = real_index + (is_ch_char and 3 or 1)
			elseif real_start_pos ~= 0 and not is_match_char then
				i = 1
				j = wide_char_match_begin
				real_index = real_start_pos + (wide_char_name[wide_char_match_begin]:byte() > 127 and 3 or 1)
				real_start_pos = 0
				wide_char_match_begin = 0
			else
				real_index = real_index + (is_ch_char and 3 or 1)
			end

			-- update real_index
			j = j + 1
		end
	else -- re match mode
		endp = 0
		while true do
			startp, endp = string.find(name, find_str, endp + 1)
			if not startp then
				break
			end
			table.insert(startPos, startp)
			table.insert(endPos, endp)
		end
	end

	if #startPos > 0 then
		return startPos, endPos
	else
		return nil, nil
	end
end

local get_first_match_label = ya.sync(function(state)
	if state.match == nil then
		return nil
	end

	for url, _ in pairs(state.match) do
		return #state.match[url].key > 0 and state.match[url].key[1] or nil
	end

	return nil
end)

-- apply search result to show
local set_match_label = ya.sync(function(state, url, name, file)
	local span = {}
	local key = {}
	local i = 1
	if state.match[url].key and #state.match[url].key > 0 then
		key = state.match[url].key
	end

	local startPos = state.match[url].startPos
	local endPos = state.match[url].endPos

	if file.is_hovered then
		table.insert(span, ui.Span(name:sub(1, startPos[1] - 1)))
	else
		table.insert(span, ui.Span(name:sub(1, startPos[1] - 1)):fg(state.opt_unmatch_fg))
	end

	while i <= #startPos do
		table.insert(span,
			ui.Span(name:sub(startPos[i], endPos[i])):fg(state.opt_match_str_fg):bg(state.opt_match_str_bg))
		if i <= #key then
			table.insert(span, ui.Span(key[i]):fg(state.opt_label_fg):bg(state.opt_label_bg))
		end
		if i + 1 <= #startPos then
			if file.is_hovered then
				table.insert(span, ui.Span(name:sub(endPos[i] + 1, startPos[i + 1] - 1)))
			else
				table.insert(span, ui.Span(name:sub(endPos[i] + 1, startPos[i + 1] - 1)):fg(state.opt_unmatch_fg))
			end
		end
		i = i + 1
	end

	if file.is_hovered then
		table.insert(span, ui.Span(name:sub(endPos[i - 1] + 1, #name)))
	else
		table.insert(span, ui.Span(name:sub(endPos[i - 1] + 1, #name)):fg(state.opt_unmatch_fg))
	end
	return span
end)

-- update the match data after input a str
local update_match_table = ya.sync(function(state, pane, folder, convert_pattern)
	if not folder then
		return
	end

	local i

	for i, file in ipairs(folder.window) do
		local name = file.name:gsub("\r", "?", 1)
		local url = tostring(file.url)
		local startPos, endPos = get_match_position(state, name, convert_pattern)
		if startPos then
			-- record match file data
			state.match[url] = {
				key = {},
				startPos = startPos,
				endPos = endPos,
				isdir = file.cha.is_dir,
				pane = pane,
				cursorPos = i,
			}
		end
	end
end)

local record_match_file = ya.sync(function(state, patterns)
	local exist_match = false

	if state.match == nil then
		state.match = {}
	end

	if state.next_char == nil then
		state.next_char = {}
	end

	for _, pattern in ipairs(patterns) do
		-- record match file from current window
		update_match_table("current", cx.active.current, pattern)

		if not state.opt_only_current then
			-- record match file from parent window
			update_match_table("parent", cx.active.parent, pattern)
			-- record match file from preview window
			update_match_table("preview", cx.active.preview.folder, pattern)
		end
	end

	-- get valid key list (KEYS_label but exclude state.next_char table)
	local valid_label = {}
	for _, value in ipairs(KEYS_label) do
		if not state.opt_enable_capital_label and string.byte(value) > 64 and string.byte(value) < 91 then
			goto nextlabel
		end

		if state.next_char[string.lower(value)] == nil then
			table.insert(valid_label, value)
		end

		::nextlabel::
	end

	-- assign valid key to each match file
	local i = 1
	local j
	for url, _ in pairs(state.match) do
		exist_match = true
		j = 1
		while j <= #state.match[url].startPos do -- some file may match multi position
			table.insert(state.match[url].key, valid_label[i])
			i = i + 1
			j = j + 1
		end
	end

	-- flush page
	if cx.active.preview.folder then
		ya.mgr_emit("peek", { force = true })
	end

	ya.render()

	return exist_match
end)

local toggle_ui = ya.sync(function(st)
	if st.highlights or st.status_sj_id then
		Status:children_remove(st.status_sj_id)
		Entity.highlights, st.highlights, st.status_sj_id = st.highlights, nil, nil
		if cx.active.preview.folder then
			ya.mgr_emit("peek", { force = true })
		end
		ya.render()
		return
	end

	st.highlights = Entity.highlights

	Entity.highlights = function(self)
		local file = self._file
		local spans = {}
		local name = file.name:gsub("\r", "?", 1)

		local url = tostring(file.url)

		if st.match and st.match[url] then
			spans = set_match_label(url, name, file)
		elseif file.is_hovered then
			spans = { ui.Span(name) }
		else
			spans = { ui.Span(name):fg(st.opt_unmatch_fg) }
		end

		return ui.Line(spans)
	end

	local function status_sj(self)
		local style = self:style()
		local match_pattern = (st.match_pattern and st.opt_show_search_in_statusbar) and ":" .. st.match_pattern or ""
		return ui.Line {
			ui.Span("[SJ]" .. match_pattern .. " "):style(style.main),
		}
	end
	st.status_sj_id = Status:children_add(status_sj, 1001, Status.LEFT)

	if cx.active.preview.folder then
		ya.mgr_emit("peek", { force = true })
	end
end)

local check_key_is_label = ya.sync(function(state, final_input_str)
	if state.backouting then
		state.backouting = false
		return nil
	end

	if not state.match then
		return nil
	end

	for url, _ in pairs(state.match) do
		for _, value in ipairs(state.match[url].key) do
			if value == final_input_str then
				return url
			end
		end
	end

	return nil
end)

local set_target_str = ya.sync(function(state, patterns, final_input_str)
	local url = check_key_is_label(final_input_str)
	if url then                                                         -- if the last str match is a label key, not a searchchar,toggle jump action
		if not state.args_autocd and state.match[url].pane == "current" then -- if target file in current pane, use `arrow` instead of`reveal` tosupport select mode
			local folder = cx.active.current
			ya.mgr_emit("arrow", { state.match[url].cursorPos - folder.cursor - 1 + folder.offset })
		elseif state.args_autocd and state.match[url].isdir then
			ya.mgr_emit("cd", { url })
		else
			ya.mgr_emit("reveal", { url })
		end
		-- two args is (want_exit,is_match)
		return true, true
	end

	-- clears the previously calculated data when input change
	state.match = nil
	state.next_char = nil

	-- calculate match data
	local exist_match = record_match_file(patterns)

	-- apply match data to render
	ya.render()
	if not exist_match and (state.re_match or patterns[1] ~= "") and state.opt_auto_exit_when_unmatch then
		return true, exist_match
	else
		return false, exist_match
	end
end)

local clear_state_str = ya.sync(function(state)
	state.match = nil
	state.next_char = nil
	state.backouting = nil
	state.match_pattern = nil
	ya.render()
end)

local backout_last_input = ya.sync(function(state, input_str)
	local final_input_str = input_str:sub(-2, -2)
	input_str = input_str:sub(1, -2)

	state.backouting = true
	state.match_pattern = input_str
	ya.render()
	return input_str, final_input_str
end)

local flush_input_key_in_statusbar = ya.sync(function(state, input_str)
	if state.re_match then
		state.match_pattern = "[~]"
	else
		state.match_pattern = input_str
	end
	ya.render()
end)

local set_args_default = ya.sync(function(state, args)
	if (args[1] ~= nil and args[1] == "autocd") then
		state.args_autocd = true
	else
		state.args_autocd = false
	end
end)

local set_opts_default = ya.sync(function(state)
	if (state.mapdata == nil) then
		state.mapdata = {}
	end

	if (state.opt_unmatch_fg == nil) then
		state.opt_unmatch_fg = "#b2a496"
	end
	if (state.opt_match_str_fg == nil) then
		state.opt_match_str_fg = "#000000"
	end
	if (state.opt_match_str_bg == nil) then
		state.opt_match_str_bg = "#73AC3A"
	end
	if (state.opt_first_match_str_fg == nil) then
		state.opt_first_match_str_fg = "#000000"
	end
	if (state.opt_first_match_str_bg == nil) then
		state.opt_first_match_str_bg = "#73AC3A"
	end
	if (state.opt_label_fg == nil) then
		state.opt_label_fg = "#EADFC8"
	end
	if (state.opt_label_bg == nil) then
		state.opt_label_bg = "#BA603D"
	end
	if (state.opt_only_current == nil) then
		state.opt_only_current = false
	end
	if (state.opt_search_patterns == nil) then
		state.opt_search_patterns = {}
	end
	if (state.opt_show_search_in_statusbar == nil) then
		state.opt_show_search_in_statusbar = false
	end
	if (state.opt_auto_exit_when_unmatch == nil) then
		state.opt_auto_exit_when_unmatch = true
	end
	if (state.opt_enable_capital_label == nil) then
		state.opt_enable_capital_label = false
	end
	return state.opt_search_patterns
end)

return {
	setup = function(state, opts)
		-- Save the user configuration to the plugin's state

		if (opts ~= nil and opts.mapdata ~= nil) then
			state.mapdata = opts.mapdata
		end

		if (opts ~= nil and opts.unmatch_fg ~= nil) then
			state.opt_unmatch_fg = opts.unmatch_fg
		end
		if (opts ~= nil and opts.match_str_fg ~= nil) then
			state.opt_match_str_fg = opts.match_str_fg
		end
		if (opts ~= nil and opts.match_str_bg ~= nil) then
			state.opt_match_str_bg = opts.match_str_bg
		end
		if (opts ~= nil and opts.first_match_str_fg ~= nil) then
			state.opt_first_match_str_fg = opts.first_match_str_fg
		end
		if (opts ~= nil and opts.first_match_str_bg ~= nil) then
			state.opt_first_match_str_bg = opts.first_match_str_bg
		end
		if (opts ~= nil and opts.label_fg ~= nil) then
			state.opt_label_fg = opts.label_fg
		end
		if (opts ~= nil and opts.label_bg ~= nil) then
			state.opt_label_bg = opts.label_bg
		end

		if (opts ~= nil and opts.only_current ~= nil) then
			state.opt_only_current = opts.only_current
		end
		if (opts ~= nil and opts.search_patterns ~= nil) then
			state.opt_search_patterns = opts.search_patterns
		end
		if (opts ~= nil and opts.show_search_in_statusbar ~= nil) then
			state.opt_show_search_in_statusbar = opts.show_search_in_statusbar
		end
		if (opts ~= nil and opts.auto_exit_when_unmatch ~= nil) then
			state.opt_auto_exit_when_unmatch = opts.auto_exit_when_unmatch
		end
		if (opts ~= nil and opts.enable_capital_label ~= nil) then
			state.opt_enable_capital_label = opts.enable_capital_label
		end
	end,

	entry = function(_, job)
		local opt_search_patterns = set_opts_default()
		set_args_default(job.args)

		toggle_ui()

		local input_str = ""
		local patterns = {}
		local final_input_str = ""
		while true do
			local cand = ya.which { cands = INPUT_CANDS, silent = true }
			if cand == nil then
				goto continue
			end

			if INPUT_KEY[cand] == "<Esc>" then
				break
			end

			if INPUT_KEY[cand] == "<Enter>" then
				final_input_str = get_first_match_label()
				patterns = ""
			elseif INPUT_KEY[cand] == "<Space>" then
				final_input_str = ""
				input_str = ""
				patterns = opt_search_patterns
				set_re_match(true)
			elseif INPUT_KEY[cand] == "<Backspace>" then
				input_str, final_input_str = backout_last_input(input_str)
				patterns = { input_str }
				set_re_match(false)
			else
				final_input_str = INPUT_KEY[cand]
				input_str = input_str .. string.lower(INPUT_KEY[cand])
				patterns = { input_str }
				set_re_match(false)
			end

			::reset::
			flush_input_key_in_statusbar(input_str)

			local want_exit, is_match = set_target_str(patterns, final_input_str)
			if want_exit then
				break
			end

			-- If the string after the entered character does not match anything, -- then the string input is cancelled and keep the previous input matches status
			if not is_match and get_re_match_state() then
				break
			elseif not is_match and input_str ~= "" then
				input_str, final_input_str = backout_last_input(input_str)
				patterns = { input_str }
				goto reset
			end
			::continue::
		end

		clear_state_str()
		toggle_ui()
	end
}
