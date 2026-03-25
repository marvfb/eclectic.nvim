local M = {}

function M.consume_inputstream(consumer)
	return function()
		local state = {}
		while true do
			local char = vim.fn.getcharstr()
			local consumed = consumer(char, state)
			if not consumed then
				vim.api.nvim_feedkeys(char, "mt", false)
				break
			end
			vim.api.nvim__redraw({ flush = true, cursor = true })
		end
	end
end

return M
