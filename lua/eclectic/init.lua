local M = {}

local util = require("eclectic.util")
local emacs = require("eclectic.emacs")

local default_config = {
	-- Keep these as vim defaults. Also works for keys
	-- that are not actually mapped (leaves them unmapped)
	-- If a bool is given, all vim defaults are preserved
	-- If a list is given, only those listed are preserved
	-- TODO: List of all of vim's default bindings
	keep = { "<Tab>" },
	readline_flavored = true,
	-- Modes for which keybindings are applied
	-- "i" for insert
	-- "c" for command
	-- "x" for visual
	-- "s" for select
	-- "n" for normal
	-- global mode mask
	modes = { "i", "c", "x", "s", "t" },
	-- These keybinding will always be applied at the highest priority
	-- and ignore the `keep` configuration option
	custom_bindings = {
		-- TODO: Add more. Also allow users to reference the plugins bindings

		-- "key"
		-- { "key", translation = "another_key"}
		-- { "key", mode_mask = { "i", "c" } },
	},
	-- TODO: Config for disabling features groups
	-- like certain modes.
}

function M.setup(user_config)
	local config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- TODO: Apply config
	local emacs_bindings = vim.tbl_extend("error", emacs.global_bindings, emacs.tab_bar_mode)

	-- TODO: Apply config
	for key, bindings in pairs(emacs_bindings) do
		if #bindings == 3 and type(bindings[2]) ~= "table" then
			-- `bindings` is a single binding
			bindings = { bindings }
		end
		for _, binding in ipairs(bindings) do
			local available_modes = util.as_table(binding[1])
			local command = binding[2]
			local opts = binding[3]

			if
				not (
					type(key) == "string"
					and (type(available_modes) == "table")
					and (type(command) == "string" or type(command) == "function")
					and type(opts) == "table"
				)
			then
				print(vim.inspect(available_modes))
				print(vim.inspect(key))
				print(vim.inspect(command))
				print(vim.inspect(opts))
			end

			if not vim.tbl_contains(config.keep, key) then
				vim.keymap.set(util.table_intersection(available_modes, config.modes), key, command, opts)
			end
		end
	end
end

return M
