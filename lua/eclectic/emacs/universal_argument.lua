local M = {}

local util = require("eclectic.util")

-- This is the internal state
local count = nil
local flag = false

local function get_count()
	-- Reset count
	local old_count = count
	count = nil
	return old_count
end

local function get_count_1()
	-- Reset count
	local old_count = count
	count = nil
	return old_count or 1
end

local function repeat_next_char()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		callback = function()
			vim.v.char = string.rep(vim.v.char, math.abs(get_count()))
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
	local sign = util.ternary(count >= 0, 1, -1)
	count = count * 10 + sign * d
end

function M.format_count(formatstr, opts)
	opts = opts or {}
	return function()
		local c = get_count_1()
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
		local c = get_count_1()
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
		return func(get_count())
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

local function get_flag()
	-- Reset flag
	local old_flag = flag
	flag = false
	return old_flag
end

function M.raise_flag()
	flag = true
end

function M.pass_flag(default_cmd, cmd_if_set)
	return function()
		if type(cmd_if_set) == type(default_cmd) == "string" then
			return util.ternary(get_flag(), cmd_if_set, default_cmd)
		elseif type(cmd_if_set) == type(default_cmd) == "function" then
			if get_flag() then
				return cmd_if_set()
			else
				return default_cmd()
			end
		end
	end
end

return M
