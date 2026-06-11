local M = {}

M.all_modes = { "i", "c", "x", "s", "t" }
M.input_modes = { "i", "c", "x", "s" }
M.navigation_modes = { "i", "x", "s" }
M.editing_modes = { "i", "c" }
M.insert_mode = "i"
M.command_mode = "c"
M.visual_mode = "x"

function M.normal_from_insert(str, reenter_how)
	reenter_how = reenter_how or "i"
	return string.format("<Esc>%s" .. reenter_how, str)
end
function M.normal_from_command(str, reenter_how)
	reenter_how = reenter_how or "i"
	return string.format("<C-f>%s" .. reenter_how .. "<C-c><Cmd>redraw<CR>", str)
end
function M.normal_from_visual(str, reenter_how)
	return str .. (reenter_how or "")
end
function M.ex_command(str)
	return string.format("<Cmd>%s<CR>", str)
end
function M.interactive_ex_command(str, cursor_adjustment)
	return string.format("<C-o>:%s" .. (cursor_adjustment or ""), str)
end
function M.visual_from_insert(str, enter_how)
	enter_how = enter_how or "v"
	return string.format("<C-o>" .. enter_how .. "%s", str)
end

function M.normal_bindings(binding)
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
		if mode == "i" then
			table.insert(bindings, { M.insert_mode, generate_cmd(M.normal_from_insert), opts })
		elseif mode == "c" then
			table.insert(bindings, { M.command_mode, generate_cmd(M.normal_from_command), opts })
		elseif mode == "x" then
			table.insert(bindings, { M.visual_mode, generate_cmd(M.normal_from_visual), opts })
		end
	end
	return bindings
end

return M
