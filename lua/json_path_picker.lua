local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local M = {}

local function format_json(value, indent)
	indent = indent or ""
	if type(value) ~= "table" then
		return tostring(value)
	end

	local result = "{\n"
	local keys = {}
	for k in pairs(value) do
		table.insert(keys, k)
	end
	table.sort(keys)

	for _, k in ipairs(keys) do
		local v = value[k]
		result = result .. indent .. "  " .. string.format("%q", k) .. ": "
		if type(v) == "table" then
			result = result .. format_json(v, indent .. "  ")
		else
			result = result .. string.format("%q", tostring(v))
		end
		result = result .. ",\n"
	end

	if result:sub(-2) == ",\n" then
		result = result:sub(1, -3) .. "\n"
	end

	return result .. indent .. "}"
end

local function split_path(path)
	if not path or type(path) ~= "string" then
		return {}
	end
	local parts = {}
	local current = ""
	local in_brackets = false

	for i = 1, #path do
		local char = path:sub(i, i)
		if char == "." and not in_brackets then
			if current ~= "" then
				table.insert(parts, current)
				current = ""
			end
		elseif char == "[" then
			if current ~= "" then
				table.insert(parts, current)
				current = ""
			end
			in_brackets = true
			current = char
		elseif char == "]" and in_brackets then
			current = current .. char
			table.insert(parts, current)
			current = ""
			in_brackets = false
		else
			current = current .. char
		end
	end

	if current ~= "" then
		table.insert(parts, current)
	end

	return parts
end

local function build_paths(parts)
	local paths = {}
	for i = #parts, 1, -1 do
		local path = table.concat(parts, ".", 1, i)
		table.insert(paths, path)
	end
	return paths
end

local function get_by_path(obj, path)
	if not path or type(path) ~= "string" then
		return nil
	end
	local parts = split_path(path)
	local current = obj
	for _, part in ipairs(parts) do
		if type(current) ~= "table" then
			return nil
		end
		if part:sub(1, 1) == "[" and part:sub(-1) == "]" then
			local index = tonumber(part:sub(2, -2))
			if index then
				current = current[index + 1] -- Lua 数组索引从 1 开始
			else
				return nil
			end
		else
			current = current[part]
		end
		if current == nil then
			return nil
		end
	end
	return current
end

local json_obj = nil

function M.pick_json_path()
	local buf = vim.api.nvim_get_current_buf()
	local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

	if filetype ~= "json" then
		vim.api.nvim_err_writeln("Current buffer is not a JSON file")
		return
	end

	local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
	json_obj = vim.fn.json_decode(content)

	if not json_obj then
		vim.api.nvim_err_writeln("Failed to parse JSON content")
		return
	end

	local function enter(prompt_bufnr)
		local selected = action_state.get_selected_entry()
		if not selected then
			return
		end
		local path = selected.value
		local result = get_by_path(json_obj, path)
		if result then
			local formatted_json_str = format_json(result)
			vim.fn.setreg("+", formatted_json_str)
			print("Copied to clipboard: " .. path)
		end
		actions.close(prompt_bufnr)
	end

	local function preview_json(entry, bufnr)
		if not entry or not entry.value then
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Invalid entry" })
			return
		end
		local path = entry.value
		local result = get_by_path(json_obj, path)
		if result then
			local formatted_json_str = format_json(result)
			local lines = vim.split(formatted_json_str, "\n")
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(bufnr, "filetype", "json")
		else
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "No data found for path: " .. path })
		end
	end

	local function run_picker(paths)
		pickers
			.new({}, {
				prompt_title = "JSON Path Picker",
				finder = finders.new_table({
					results = paths,
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry,
							ordinal = entry,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				previewer = previewers.new_buffer_previewer({
					title = "JSON Preview",
					define_preview = function(self, entry, status)
						preview_json(entry, self.state.bufnr)
					end,
				}),
				attach_mappings = function(prompt_bufnr, map)
					map("i", "<CR>", enter)
					map("n", "<CR>", enter)
					return true
				end,
			})
			:find()
	end

	vim.ui.input({ prompt = "Enter JSON path: " }, function(input)
		if input then
			local parts = split_path(input)
			local paths = build_paths(parts)
			run_picker(paths)
		end
	end)
end

return M
