local M = {}

-- TODO: How should this interact with expr?

local universal_argument = require("eclectic.emacs.universal_argument")

function M.goto_line() end

function M.goto_char() end

function M.move_rest_of_line_down() end

function M.squeeze_blank_lines() end

function M.transpose_characters() end

function M.transpose_words() end

function M.transpose_lines() end

function M.universal_argument()
	vim.ui.input({}, function(input)
		local num = tonumber(input)
		if type(num) == "number" then
			universal_argument.set_count(num)
		else
			-- Trigger boolean argument
			universal_argument.set_count(1)
		end
	end)
end

return M
