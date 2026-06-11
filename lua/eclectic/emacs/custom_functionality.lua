local M = {}

local universal_argument = require("eclectic.emacs.universal_argument")
local input_handling = require("eclectic.emacs.input_handling")
local util = require("eclectic.common.util")

-- Does not work correctly for some reason
function M.recenter_top_bottom()
	local action = function(cycle)
		local action = ""
		if cycle == 0 then
			action = "zz"
		elseif cycle == 1 then
			action = "zt"
		elseif cycle == 2 then
			action = "zb"
		end
		local arg = universal_argument.get_count()
		if arg then
			action = string.format("%dzt", math.max(1, arg))
		end
		vim.cmd.normal(action)
	end
	-- Needs to execute once for the initial C-l
	action(0)
	input_handling.consume_inputstream(function(char, state)
		state.cycle = state.cycle or 1
		if char == util.termcode_escape("<C-l>") then
			action(state.cycle)
			state.cycle = (state.cycle + 1) % 3
			return true
		else
			return false
		end
	end)()
end

function M.move_rest_of_line_down() end

function M.delete_blank_lines() end

function M.set_fill_column() end

function M.transpose_characters() end

function M.transpose_words() end

function M.transpose_lines() end

return M
