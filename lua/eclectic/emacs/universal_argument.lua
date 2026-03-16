local M = {}

-- This is the internal count
local count = 0

function M.count()
	-- Reset count
	local old_count = count
	count = 0
	return old_count
end

function M.nonzero_count()
	local c = M.count()
	return c == 0 and 1 or c
end

function M.nonnegative_count()
	return math.abs(M.count())
end

function M.positive_count()
	return math.max(1, M.count())
end

-- TODO: Use once option instead
local function repeat_next_char()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		pattern = "*",
		callback = function(ev)
			vim.api.nvim_del_autocmd(ev.id)
			vim.v.char = string.rep(vim.v.char, M.positive_count())
		end,
	})
end

function M.set_count(c)
	repeat_next_char()
	count = c
end

function M.add_digit(d)
	if count == 0 then
		repeat_next_char()
	end
	local sign = count >= 0 and 1 or -1
	count = count * 10 + sign * d
end

function M.format_count(formatstr, count_func, opposite_formatstr)
	return function()
		local c = count_func()
		if c < 0 and opposite_formatstr then
			formatstr = opposite_formatstr
		end
		return string.format(formatstr, math.abs(c))
	end
end

function M.repeat_times(cmd, count_func, opposite_cmd)
	return function()
		local c = count_func()
		if c < 0 and opposite_cmd then
			cmd = opposite_cmd
		end
		if type(cmd) == "string" then
			return string.rep(cmd, math.abs(c))
		elseif type(cmd) == "function" then
			for _ = 1, math.abs(c) do
				cmd()
			end
		end
	end
end

function M.pass_count(func, count_func)
	return function()
		func(count_func())
	end
end

function M.pass_flag(func)
	return function()
		func(M.count() ~= 0)
	end
end

return M
