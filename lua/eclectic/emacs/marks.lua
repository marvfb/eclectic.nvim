local M = {}

-- TODO: Add cleanup functions

-- TODO: Carefully think about default

local mark_ring = {}

local global_mark_ring = {}

function M.push_mark_ring()
	local bufnr = vim.fn.bufnr()
	local pos = vim.api.nvim_win_get_cursor(0)
	if not mark_ring[bufnr] then
		mark_ring[bufnr] = {}
	end
	table.insert(mark_ring[bufnr], 1, pos)
end

function M.peek_mark_ring()
	local bufnr = vim.fn.bufnr()
	if not mark_ring[bufnr] then
		mark_ring[bufnr] = {}
	end
	return mark_ring[bufnr][1]
end

function M.pop_mark_ring()
	local ret = M.peek_mark_ring()
	local bufnr = vim.fn.bufnr()
	if #mark_ring >= 2 then
		table.move(mark_ring[bufnr], 2, 1, #mark_ring[bufnr])
	else
		mark_ring[bufnr][1] = nil
	end
	return ret
end

function M.jump_mark_ring()
	local pos = M.peek_mark_ring()
	if pos then
		vim.api.nvim_win_set_cursor(0, pos)
	else
		vim.cmd.normal("<Esc>")
	end
end

function M.push_global_mark_ring()
	local bufnr = vim.fn.bufnr()
	local pos = vim.api.nvim_win_get_cursor(0)
	table.insert(global_mark_ring, 1, { bufnr, pos })
end

function M.peek_global_mark_ring()
	return global_mark_ring[1]
end

function M.pop_global_mark_ring()
	local ret = global_mark_ring[1]
	if #global_mark_ring >= 2 then
		table.move(global_mark_ring, 2, 1, #global_mark_ring)
	else
		global_mark_ring[1] = nil
	end
	return ret
end

function M.jump_global_mark_ring()
	if global_mark_ring[1] then
		local bufnr, pos = unpack(global_mark_ring[1])
		vim.api.nvim_win_set_buf(0, bufnr)
		vim.api.nvim_win_set_cursor(0, pos)
	else
		vim.cmd.normal("<Esc>")
	end
end

return M
