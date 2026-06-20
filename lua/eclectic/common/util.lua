local M = {}

function M.clamp(num, min, max)
	return math.max(min, math.min(max, num))
end

function M.ternary(expr, if_true, if_false)
	return expr and if_true or if_false
end

function M.termcode_escape(str)
	return vim.api.nvim_replace_termcodes(str, true, false, true)
end

function M.list_intersection(table1, table2)
	local res = {}
	for _, val in ipairs(table1) do
		if vim.list_contains(table2, val) then
			table.insert(res, val)
		end
	end
	return res
end

function M.list_difference(table1, table2)
	local res = {}
	for _, val in ipairs(table1) do
		if not vim.list_contains(table2, val) then
			table.insert(res, val)
		end
	end
	return res
end

function M.as_table(obj)
	return M.ternary(type(obj) == "table", obj, { obj })
end

return M
