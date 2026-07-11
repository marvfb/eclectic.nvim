local M = {}
M.modes = {}
M.actions = {}

M.modes.all_modes = { "n", "i", "s", "x", "c", "t" }
M.modes.nonterminal_modes = { "n", "i", "s", "x", "c" }
M.modes.navigation_modes = { "n", "i", "s", "x" }
M.modes.editing_modes = { "i", "s", "c" }
M.modes.normal_mode = "n"
M.modes.insert_mode = "i"
M.modes.select_mode = "s"
M.modes.visual_mode = "x"
M.modes.command_mode = "c"
M.modes.terminal_mode = "t"

M.actions.normal = {}
function M.actions.normal.from_mode(mode)
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

M.actions.visual = {}
function M.actions.visual.from_mode(mode)
	return function(str, enter_how)
		enter_how = enter_how or "v"
		if mode == "n" then
			return "<Cmd>normal " .. enter_how .. str .. "<CR>"
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

function M.actions.ex_command(str)
	return "<Cmd>" .. str .. "<CR>"
end

M.actions.interactive_ex_command = {}
function M.actions.interactive_ex_command.from_mode(mode)
	return function(str, enter_how)
		enter_how = enter_how or ":"
		if mode == "n" or mode == "x" then
			return enter_how .. str
		elseif mode == "i" or mode == "s" then
			return "<Esc>" .. enter_how .. str
		elseif mode == "c" then
			return str
		elseif mode == "t" then
			return "<C-\\><C-n>" .. enter_how .. str
		end
		error("unexpected mode: " .. mode)
		return nil
	end
end

M.actions.interactive_visual = {}
function M.actions.interactive_visual.from_mode(mode)
	return function(str, enter_how)
		enter_how = enter_how or "v"
		if mode == "n" then
			return enter_how .. str
		elseif mode == "x" then
			-- TODO: how do v V and C-v interact
			return str
		elseif mode == "i" or mode == "s" then
			return "<Esc>" .. enter_how .. str
		elseif mode == "t" then
			return "<C-\\><C-n>" .. enter_how .. str
		end
		error("unexpected mode: " .. mode)
		return nil
	end
end

local function kind_bindings(kind)
	return function(binding)
		local modes = binding[1]
		local generate_cmd = binding[2]
		local opts = binding[3]

		if not (type(modes) == "table" and type(generate_cmd) == "function" and type(opts) == "table") then
			print(vim.inspect(modes))
			print(vim.inspect(generate_cmd))
			print(vim.inspect(opts))
		end

		local bindings = {}
		for _, m in ipairs(modes) do
			table.insert(bindings, { m, generate_cmd(kind.from_mode(m)), opts })
		end

		return bindings
	end
end

for k1, a in pairs(M.actions) do
	for k2, m in pairs(M.modes) do
		if type(a) == "table" and type(m) == "string" then
			k2 = string.gsub(k2, "_mode", "")
			assert(type(M.actions[k1]) ~= "function", "wtf")

			M.actions[k1]["from_" .. k2] = M.actions[k1].from_mode(m)
			M.actions[k1].bindings = kind_bindings(a)
		end
	end
end

function M.bindings(binding)
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
		local actions = {}
		for n, a in pairs(M.actions) do
			if type(a) == "table" then
				actions[n] = a.from_mode(mode)
			end
		end
		table.insert(bindings, { mode, generate_cmd(actions), opts })
	end

	return bindings
end

return M
