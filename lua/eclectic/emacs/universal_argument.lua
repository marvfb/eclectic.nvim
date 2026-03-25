local M = {}

local util = require("eclectic.util")

-- This is the internal state
local count = nil
local num_prefixes = 0

function M.get_count()
	local old_count = count
	-- Reset state
	count = nil
	num_prefixes = 0
	return old_count
end

-- TODO: Does not work in command mode
-- Also needs to expand abbrevs. see `self-insert-command`
local function repeat_next_char()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		callback = function()
			vim.v.char = string.rep(vim.v.char, math.abs(M.get_count() or 1))
		end,
		once = true,
	})
end

function M.set_count(c)
	repeat_next_char()
	count = c
end

function M.add_digit(d)
	if count == nil then
		count = 0
		repeat_next_char()
	end
	count = count * 10 + d
end

function M.format_count(formatstr, opts)
	opts = opts or {}
	return function()
		local c = M.get_count()
		if c == nil then
			if opts.default and type(opts.default) == "number" then
				c = opts.default
			elseif opts.default and type(opts.default) == "function" then
				c = opts.default()
			else
				c = 1
			end
		end
		if c < 0 and opts.opposite then
			formatstr = opts.opposite
		end
		if c == 0 then
			if not opts.zero then
				return ""
			end
			if type(opts.zero) == "string" then
				return opts.zero
			elseif type(opts.zero) == "function" then
				return opts.zero()
			end
		end
		if type(formatstr) == "string" then
			return string.format(formatstr, math.abs(c))
		elseif type(formatstr) == "function" then
			return string.format(formatstr(), math.abs(c))
		end
	end
end

function M.repeat_times(cmd, opts)
	opts = opts or {}
	return function()
		local c = M.get_count()
		if c == nil then
			if opts.default and type(opts.default) == "number" then
				c = opts.default
			elseif opts.default and type(opts.default) == "function" then
				c = opts.default()
			else
				c = 1
			end
		end
		if c < 0 and opts.opposite then
			cmd = opts.opposite
		end
		if c == 0 then
			if type(cmd) == "string" then
				return opts.zero or ""
			elseif type(cmd) == "function" then
				return opts.zero or function() end
			end
		end
		if type(cmd) == "string" then
			return string.rep(cmd, math.abs(c))
		elseif type(cmd) == "function" then
			local res = ""
			for _ = 1, math.abs(c) do
				res = res .. (cmd() or "")
			end
			return res
		end
	end
end

function M.pass_count(func)
	return function()
		return func(M.get_count())
	end
end

function M.get_num_prefixes()
	local old_num_prefixes = num_prefixes
	-- Reset state
	count = nil
	num_prefixes = 0
	return old_num_prefixes
end

function M.add_prefix()
	num_prefixes = num_prefixes + 1
end

function M.prefix_argument(...)
	local cmds = { ... }
	return function()
		-- If there was a count, the initial C-u is not a prefix argument
		local offset = util.ternary(count == nil, 1, 0)
		local cmd = cmds[M.get_num_prefixes() + offset]
		if type(cmd) == "string" then
			return cmd
		elseif type(cmd) == "function" then
			return cmd()
		end
	end
end

function M.sequence(...)
	local cmds = { ... }
	return function()
		local res = ""
		for _, cmd in ipairs(cmds) do
			if type(cmd) == "string" then
				res = res .. cmd
			elseif type(cmd) == "function" then
				res = res .. (cmd() or "")
			end
		end
		return res
	end
end

return M
