local M = {}

function M.clamp(num, min, max)
	return math.max(min, math.min(max, num))
end

function M.ternary(expr, if_true, if_false)
	return expr and if_true or if_false
end

function M.in_table(val, table)
	for _, v in ipairs(table) do
		if v == val then
			return true
		end
	end
	return false
end

return M
