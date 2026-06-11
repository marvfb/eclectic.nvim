local M = {}

-- TODO: Find better names

M.all_modes = { "i", "c", "x", "s", "t" }
M.input_modes = { "i", "c", "x", "s" }
M.navigation_modes = { "i", "x", "s" }
M.editing_modes = { "i", "c" }
M.insert_mode = "i"
M.command_mode = "c"
M.visual_mode = "x"
M.terminal_mode = "t"

local mt = {}
function mt.__index(table, key)
	local mode = string.match(key, "^from_(.).*")
	-- from_visual should work
	string.gsub(mode, "v", "x")
	return table.from_mode(mode)
end

M.normal = {}
setmetatable(M.normal, mt)
function M.normal.from_mode(mode)
	return function(str, reenter_how)
		reenter_how = reenter_how or "i"
		if mode == "n" or mode == "x" then
			return str .. reenter_how
		elseif mode == "i" or mode == "s" then
			return "<Esc>" .. str .. reenter_how
		elseif mode == "c" then
			return "<C-f>" .. reenter_how .. "<C-c><Cmd>redraw<CR>"
		elseif mode == "t" then
			return "<C-\\><C-n>" .. str .. (reenter_how or "i")
		end
		error("unexpected mode: " .. mode)
		return nil
	end
end

function M.ex_command(str)
	return "<Cmd>" .. str .. "<CR>"
end

M.interactive_ex_command = {}
setmetatable(M.interactive_ex_command, mt)
function M.interactive_ex_command.from_mode(mode)
	return function(str, cursor_adjustment)
		cursor_adjustment = cursor_adjustment or ""
		if mode == "n" or mode == "x" then
			return ":" .. str .. cursor_adjustment
		elseif mode == "i" or mode == "s" then
			return "<Esc>:" .. str .. cursor_adjustment
		elseif mode == "c" then
			return str .. cursor_adjustment
		elseif mode == "t" then
			return "<C-\\><C-n>:" .. str .. cursor_adjustment
		end
		error("unexpected mode: " .. mode)
		return nil
	end
end

M.interactive_visual = {}
setmetatable(M.interactive_visual, mt)
function M.interactive_visual.from_mode(mode)
	return function(str, enter_how)
		enter_how = enter_how or "x"
		if mode == "n" then
			return enter_how .. str
		elseif mode == "v" then
			return "" .. str
		elseif mode == "i" or mode == "s" then
			return "<Esc>" .. enter_how .. str
		elseif mode == "t" then
			return "<C-\\><C-n>" .. enter_how .. str
		end
		error("unexpected mode: " .. mode)
		return nil
	end
end

function M.bindings(kind, binding)
	local modes = binding[1]
	local generate_cmd = binding[2]
	local opts = binding[3]

	if not (type(modes) == "table" and type(generate_cmd) == "function" and type(opts) == "table") then
		print(vim.inspect(modes))
		print(vim.inspect(generate_cmd))
		print(vim.inspect(opts))
	end

	local bindings = {}
	for _, mode in ipairs(modes) do
		assert(kind["from_" .. mode], "Indexing doesnt work")
		table.insert(bindings, { mode, generate_cmd(kind["from_" .. mode]), opts })
	end

	return bindings
end

return M
