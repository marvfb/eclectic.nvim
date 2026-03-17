local M = {}

-- TODO: Implement

local util = require("eclectic.util")
local universal_argument = require("eclectic.emacs.universal_argument")

function M.goto_line() end

function M.goto_char() end

function M.zap_to_char() end

function M.yank_commandline() end

function M.move_rest_of_line_down() end

function M.delete_blank_lines() end

function M.set_fill_column() end

function M.transpose_characters() end

function M.transpose_words() end

function M.transpose_lines() end

function M.universal_argument()
	local first = true
	while true do
		local char = vim.fn.getcharstr()
		local digit = tonumber(char)
		if digit then
			universal_argument.add_digit(util.clamp(digit, 0, 9))
		else
			if first then
				universal_argument.raise_flag()
			end
			vim.api.nvim_feedkeys(char, "mt", false)
			break
		end
	end
end

function M.negative_argument()
	local first = true
	while true do
		local char = vim.fn.getcharstr()
		local digit = tonumber(char)
		if digit then
			if first then
				universal_argument.set_count(-digit)
			else
				universal_argument.add_digit(util.clamp(digit, 0, 9))
			end
		else
			vim.api.nvim_feedkeys(char, "mt", false)
			break
		end
	end
end

return M
