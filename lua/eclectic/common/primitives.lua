local M = {}

-- TODO: Refactor away metatable. Use for loop instead since variants are known beforehand

M.all_modes = { "n", "i", "s", "x", "c", "t" }
M.nonterminal_modes = { "n", "i", "s", "x", "c" }
M.navigation_modes = { "n", "i", "s", "x" }
M.editing_modes = { "i", "s", "c" }
M.normal_mode = "n"
M.insert_mode = "i"
M.select_mode = "s"
M.visual_mode = "x"
M.command_mode = "c"
M.terminal_mode = "t"

local mt = {}
function mt.__index(table, key)
	local mode = string.match(key, "^from_(.).*")
	-- from_visual should work
	mode = string.gsub(mode, "v", "x")
	return table.from_mode(mode)
end

M.normal = {}
setmetatable(M.normal, mt)
function M.normal.from_mode(mode)
	return function(str)
		if mode == "n" or mode == "x" then
			return str
		elseif mode == "i" or mode == "s" then
			return "<Cmd>normal " .. str .. "<CR>"
		elseif mode == "c" then
			return "<C-f>" .. str .. "<C-c><Cmd>redraw<CR>"
		elseif mode == "t" then
			return "<C-\\><C-o>" .. str
		end
		error("unexpected mode: " .. mode)
		return nil
	end
end

M.visual = {}
setmetatable(M.visual, mt)
function M.visual.from_mode(mode)
	return function(str, enter_how)
		enter_how = enter_how or "v"
		if mode == "n" then
			return enter_how .. str .. "<Esc>"
		elseif mode == "x" then
			-- TODO: how do v V and C-v interact
			return str .. "gv"
		elseif mode == "i" or mode == "s" then
			return "<Cmd>normal " .. enter_how .. str .. "<CR>"
		elseif mode == "c" then
			return "<C-f>" .. enter_how .. str .. "<C-c><Cmd>redraw<CR>"
		elseif mode == "t" then
			return "<C-\\><C-o>" .. enter_how .. str
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
		enter_how = enter_how or "v"
		if mode == "n" then
			return enter_how .. str
		elseif mode == "x" then
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
		assert(kind["from_" .. mode], "Unkown kind")
		table.insert(bindings, { mode, generate_cmd(kind["from_" .. mode]), opts })
	end

	return bindings
end

return M
