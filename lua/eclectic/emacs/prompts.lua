local M = {}

function M.prompt_count()
	local res = 0
	vim.ui.input({}, function(input)
		local num = tonumber(input)
		res = num or 0
	end)
	return res
end

return M
