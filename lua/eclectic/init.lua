local M = {}

local emacs = require("eclectic.emacs")

local default_config = {
	-- Keep these as vim defaults. Also works for keys
	-- that are not actually mapped (leaves them unmapped)
	-- If a bool is given, all vim defaults are preserved
	-- If a list is given, only those listed are preserved
	-- TODO: List of all of vim's default bindings
	keep = false,
	priorities = { "readline", "emacs", "word" },
	-- Modes for which keybindings are applied
	-- "i" for insert
	-- "c" for command
	-- "!" for both (supposedly)
	modes = { "i", "c" },
	-- These keybinding will always be applied at the highest priority
	-- and ignore the `keep` configuration option
	always_apply = {
		-- TODO: Add more
		{ { "i", "c" }, "<C-<>", "<C-o><<", { desc = "deindent line" } },
		{ { "i", "c" }, "<C->>", "<C-o>>>", { desc = "indent line" } },
	},
}

function M.setup(user_config)
	local config = vim.tbl_deep_extend("force", default_config, user_config or {})

	local normal_command = function(str)
		return string.format("<C-o>%s", str)
	end
	local ex_command = function(str)
		return string.format("<Cmd>%s<CR>", str)
	end
	local interactive_ex_command = function(str, cursor_adjustment)
		return string.format("<C-o>:%s" .. (cursor_adjustment or ""), str)
	end

	local emacs_bindings = emacs.generate_bindings(normal_command, ex_command, interactive_ex_command)

	-- TODO: Apply config
	for _, binding in ipairs(emacs_bindings) do
		local available_modes = binding[1]
		local keys = type(binding[2]) == "string" and { binding[2] } or binding[2]
		local command = binding[3]
		local opts = binding[4]

		if
			not (
				type(keys) == "table"
				and (type(available_modes) == "string" or type(available_modes) == "table")
				and (type(command) == "string" or type(command) == "function")
				and type(opts) == "table"
			)
		then
			print(vim.inspect(key))
			print(vim.inspect(available_modes))
			print(vim.inspect(command))
			print(vim.inspect(opts))
		end
		for _, key in ipairs(keys) do
			vim.keymap.set(available_modes, key, command, opts)
		end
	end
end

return M
