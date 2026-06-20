local M = {}

local util = require("eclectic.common.util")
local primitives = require("eclectic.common.primitives")

local editors = {
	emacs = require("eclectic.emacs"),
}

local default_config = {
	emacs = {
		-- Defines a set of rules for allowed keybindings. Has a lower priority than deny_rules.
		allow_rules = {
			-- "Key regex"
			-- { "Key regex", { modes }}
			{ ".*", { "i", "c" } },
		},
		-- Defines a set of rules for denied keybindings. Has a higher priority than allow_rules.
		deny_rules = {
			-- "Key regex"
			-- { "Key regex", { modes } }
			"<Tab>",
			"<C-g>",
		},
		key_translations = {
			-- ["Key"] = "Other key"
		},
		extra_features = { "tab_bar_mode" },
	},
}

local function allowed_modes(key, proposed_modes, allow_rules, deny_rules)
	local possible_modes = {}

	for _, rule in ipairs(allow_rules) do
		rule = util.as_table(rule)
		local pattern = rule[1]
		local modes = util.as_table(rule[2] or primitives.all_modes)
		if string.match(key, pattern) then
			possible_modes = vim.tbl_extend("keep", possible_modes, modes)
		end
	end
	for _, rule in ipairs(deny_rules) do
		rule = util.as_table(rule)
		local pattern = rule[1]
		local modes = util.as_table(rule[2] or primitives.all_modes)
		if string.match(key, pattern) then
			possible_modes = util.table_difference(possible_modes, modes)
		end
	end
	return util.table_intersection(proposed_modes, possible_modes)
end

function M.apply_config(user_config)
	local config = vim.tbl_deep_extend("force", default_config, user_config or {})

	for name, cfg in pairs(config) do
		local editor = editors[name]
		local bindings = editor.global_bindings
		for _, feat in ipairs(cfg.extra_features) do
			bindings = vim.tbl_extend("error", bindings, editor[feat])
		end

		for key, bindings in pairs(bindings) do
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

				vim.keymap.set(
					allowed_modes(key, available_modes, cfg.allow_rules, cfg.deny_rules),
					cfg.key_translations[key] or key,
					command,
					opts
				)
			end
		end
	end
end

return M
