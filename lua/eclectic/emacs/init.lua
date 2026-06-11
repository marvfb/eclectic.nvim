local M = {}

local util = require("eclectic.common.util")
local primitives = require("eclectic.common.primitives")

local uarg = require("eclectic.emacs.universal_argument")
local marks = require("eclectic.emacs.marks")
local custom_functionality = require("eclectic.emacs.custom_functionality")
local input_handling = require("eclectic.emacs.input_handling")
local prompts = require("eclectic.emacs.prompts")

-- Dont wanna do: Help, Emacs Lisp interpreter, support for frames and pages,
-- recursive edit, crazy emacs indentation (including fill columns and fill prefix)
-- email, language modes

-- F keys, delete keys, arrow keys were not considered

-- Features to implement: Kmacros, xrefs (tags), abbrevs (there is a one-to-one thing in nvim)

-- TODO: Implement sexps, defuns, list as a text objects using treesitter.
-- Just search for all associated bindings in C-h b
-- https://github.com/neovim/neovim/commit/72d3a57f270fdca5e592dcf2e4b7c3b00549c05e

-- TODO: Improve error handling. Use pcall, error, assert where needed.

-- TODO: Search for all mentions of marks, v, visual, etc. and consider transient mark mode and implicit region

-- Use ex long form commands where possible

local function select_other_window(normal, opts)
	opts = opts or {}
	local reverse = opts.reverse or false
	return function()
		local num_windows = #vim.api.nvim_tabpage_list_wins(0)
		local res = ""
		if num_windows < 2 then
			res = res .. primitives.ex_command("new")
		end
		return res .. normal("<C-w>" .. util.ternary(reverse, "p", "w"))
	end
end
local get_cwd = "<C-r>=getcwd()<CR>"

-- Follows the Emacs Help Page for all defined keys
-- For an introduction to Emacs Keybindings, please refer to the Emacs Reference Card
M.global_bindings = {
	-- Implemented in a better way for performance reasons. Given as a comment for completeness.
	-- "*" represents an arbitrary typable character here.
	-- ["*"] = normal_bindings({
	-- 	editing_modes,
	-- 	function()
	-- 		return uarg.repeat_times("*")
	-- 	end,
	-- 	{ desc = "self-insert-command", expr = true },
	-- }),

	["<C-@>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.prefix_argument(function()
				marks.push_mark_ring()
				marks.push_global_mark_ring()
				return normal("v")
			end, function()
				marks.jump_mark_ring()
				marks.pop_mark_ring()
			end)
		end,
		{ desc = "set-mark-command", expr = true },
	}),
	["<C-a>"] = {
		unpack(primitives.normal_bindings({
			primitives.navigation_modes,
			-- Has to be this way since a failed h/j/k/l cancels the command
			function()
				return uarg.pass_count(function(count)
					count = (count or 1) - 1
					return "<Home>" .. string.rep(util.ternary(count > 0, "<Down>", "<Up>"), math.abs(count))
				end)
			end,
			{ desc = "move-beggining-of-line", expr = true },
		})),
		{
			primitives.command_mode,
			uarg.repeat_times("<Home>", { opposite = "<End>" }),
			{ desc = "move-beggining-of-line", expr = true },
		},
	},
	["<C-b>"] = {
		primitives.input_modes,
		uarg.repeat_times("<Left>", { opposite = "<Right>" }),
		{ desc = "backward-char", expr = true },
	},
	["<C-d>"] = {
		primitives.editing_modes,
		uarg.repeat_times("<Del>", { opposite = "<Bs>" }),
		{ desc = "delete-char", expr = true },
	},
	["<C-e>"] = {
		unpack(primitives.normal_bindings({
			primitives.navigation_modes,
			-- Has to be this way since a failed h/j/k/l cancels the command
			function()
				return uarg.pass_count(function(count)
					count = (count or 1) - 1
					return "<End>" .. string.rep(util.ternary(count > 0, "<Down>", "<Up>"), math.abs(count))
				end)
			end,
			{ desc = "move-end-of-line", expr = true },
		})),
		{
			primitives.command_mode,
			uarg.repeat_times("<End>", { opposite = "<Home>" }),
			{ desc = "move-end-of-line", expr = true },
		},
	},
	["<C-f>"] = {
		primitives.input_modes,
		uarg.repeat_times("<Right>", { opposite = "<Left>" }),
		{ desc = "forward-char", expr = true },
	},
	-- TODO: Special interaction with searching and other stuff
	["<C-g>"] = { primitives.command_mode, "<Esc>", { desc = "keyboard-quit" } },
	-- C-j is already a neovim binding
	["<C-k>"] = {
		{
			primitives.insert_mode,
			uarg.format_count(
				primitives.normal_from_insert("%dD"),
				{ opposite = primitives.normal_from_insert("v0%dkd"), zero = primitives.normal_from_insert("v0d") }
			),
			{ desc = "kill-line", expr = true },
		},
		{
			primitives.command_mode,
			uarg.format_count(
				primitives.normal_from_command("D"),
				{ opposite = primitives.normal_from_command("v0d"), zero = primitives.normal_from_command("v0d") }
			),
			{ desc = "kill-line", expr = true },
		},
	},
	["<C-l>"] = {
		primitives.navigation_modes,
		custom_functionality.recenter_top_bottom,
		{ desc = "recenter-top-bottom" },
	},
	["<C-n>"] = {
		primitives.input_modes,
		uarg.repeat_times("<Down>", { opposite = "<Up>" }),
		{ desc = "next-line", expr = true },
	},
	-- TODO: Fill prefix
	["<C-o>"] = {
		primitives.insert_mode,
		uarg.repeat_times(primitives.normal_from_insert("O")),
		{ desc = "next-line", expr = true },
	},
	["<C-p>"] = {
		primitives.input_modes,
		uarg.repeat_times("<Up>", { opposite = "<Down>" }),
		{ desc = "previous-line", expr = true },
	},
	-- C-q exists already
	["<C-r>"] = {
		{ primitives.insert_mode, primitives.normal_from_insert("?", ""), { desc = "isearch-backward" } },
		{ primitives.visual_mode, "?", { desc = "isearch-backward" } },
		{ primitives.command_mode, "<C-t>", { desc = "isearch-backward" } },
	},
	["<C-s>"] = {
		{ primitives.insert_mode, primitives.normal_from_insert("/", ""), { desc = "isearch-forward" } },
		{ primitives.visual_mode, "/", { desc = "isearch-forward" } },
		{ primitives.command_mode, "<C-g>", { desc = "isearch-forward" } },
	},
	["<C-t>"] = primitives.normal_bindings({
		primitives.editing_modes,
		function(normal)
			return uarg.format_count(normal("x<Left>%s<Right>p"), { opposite = normal("x<Left>%s<Left>p") })
		end,
		{ desc = "transpose-chars", expr = true },
	}),
	["<C-u>"] = {
		primitives.input_modes,
		input_handling.consume_inputstream(function(char)
			local digit = tonumber(char)
			if digit then
				uarg.add_digit(digit)
				return true
			elseif char == util.termcode_escape("<C-u>") then
				uarg.add_prefix()
				return true
			else
				-- For first press
				uarg.add_prefix()
				return false
			end
		end),
		{ desc = "universal-argument" },
	},
	-- TODO: This is not accurate
	["<C-v>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function()
			return uarg.repeat_times("<PageUp>", { opposite = "<PageDown>" })
		end,
		{ desc = "scroll-up-command", expr = true },
	}),
	-- TODO: Test
	["<C-w>"] = {
		{
			primitives.insert_mode,
			function()
				vim.cmd.normal("v")
				marks.jump_mark_ring()
				vim.cmd.normal("d")
			end,
			{ desc = "kill-region" },
		},
		{ primitives.visual_mode, "d", { desc = "kill-region" } },
	},
	["<C-y>"] = {
		{
			primitives.insert_mode,
			uarg.prefix_argument(primitives.normal_from_insert("p", "a"), primitives.normal_from_insert("p", "`[i")),
			{ desc = "yank", expr = true },
		},
		{
			primitives.command_mode,
			uarg.prefix_argument(
				uarg.format_count("<C-r>%d", { zero = "<C-r>0", default = 0 }),
				uarg.sequence(function()
					local unnammed_register = vim.fn.getreg('"')
					string.gsub(unnammed_register, "\n", " ")
					vim.fn.setreg('"', unnammed_register)
					-- Command buffer has own set of marks
				end, primitives.normal_from_command("mzi<Left><Esc>p`z"))
			),
			{ desc = "yank", expr = true },
		},
	},
	["<C-z>"] = { primitives.input_modes, primitives.ex_command("suspend"), { desc = "suspend-frame" } },
	-- C-\ unimplemented
	-- C-] unimplemented
	["<C-_>"] = {
		primitives.insert_mode,
		uarg.format_count(primitives.normal_from_insert("%du")),
		{ desc = "undo", expr = true },
	},
	["<C-->"] = {
		primitives.input_modes,
		input_handling.consume_inputstream(function(char)
			local digit = tonumber(char)
			if digit then
				uarg.add_digit(-digit)
				return true
			else
				return false
			end
		end),
		{ desc = "negative-argument" },
	},
	["<C-0>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(0)
		end,
		{ desc = "digit-argument" },
	},
	["<C-1>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(1)
		end,
		{ desc = "digit-argument" },
	},
	["<C-2>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(2)
		end,
		{ desc = "digit-argument" },
	},
	["<C-3>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(3)
		end,
		{ desc = "digit-argument" },
	},
	["<C-4>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(4)
		end,
		{ desc = "digit-argument" },
	},
	["<C-5>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(5)
		end,
		{ desc = "digit-argument" },
	},
	["<C-6>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(6)
		end,
		{ desc = "digit-argument" },
	},
	["<C-7>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(7)
		end,
		{ desc = "digit-argument" },
	},
	["<C-8>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(8)
		end,
		{ desc = "digit-argument" },
	},
	["<C-9>"] = {
		primitives.input_modes,
		function()
			uarg.add_digit(9)
		end,
		{ desc = "digit-argument" },
	},
	["<C-?>"] = {
		primitives.insert_mode,
		uarg.format_count(primitives.normal_from_insert("%d<C-r>")),
		{ desc = "undo-redo" },
	},
	-- TODO: test
	["<C-S-Bs>"] = {
		primitives.insert_mode,
		uarg.format_count(
			primitives.normal_from_insert("%ddd"),
			{ opposite = primitives.normal_from_insert("V%dkd"), zero = primitives.normal_from_insert("0d$") }
		),
		{ desc = "kill-whole-line", expr = true },
	},
	-- C-Bs exists as a default

	-- TODO: Find appropriate help pages for all of these
	["<C-h>a"] = { primitives.insert_mode, primitives.interactive_ex_command("help "), { desc = "about-emacs" } },

	["<C-x><C-@>"] = {
		primitives.navigation_modes,
		function()
			marks.jump_global_mark_ring()
			marks.pop_global_mark_ring()
		end,
		{ desc = "pop-global-mark" },
	},
	["<C-x><C-b>"] = { primitives.all_modes, primitives.ex_command("ls"), { desc = "list-buffers" } },
	["<C-x><C-c>"] = {
		primitives.all_modes,
		uarg.prefix_argument(primitives.ex_command("qa"), primitives.ex_command("wqa")),
		{ desc = "save-buffers-kill-terminal", expr = true },
	},
	["<C-x><C-d>"] = {
		primitives.insert_mode,
		primitives.interactive_ex_command("e " .. get_cwd),
		{ desc = "list-directory" },
	},
	["<C-x><C-f>"] = {
		primitives.insert_mode,
		primitives.interactive_ex_command("e " .. get_cwd),
		{ desc = "find-file" },
	},
	-- TODO: incorrect. is technically its own modes
	["<C-x><Tab>"] = {
		primitives.visual_mode,
		uarg.sequence(uarg.repeat_times(">gv", { opposite = "<gv" }), "v"),
		{ desc = "indent region rigidly arg columns", expr = true },
	},
	["<C-x><C-j>"] = {
		primitives.all_modes,
		primitives.ex_command("e ."),
		{ desc = "dired-jump" },
	},
	["<C-x><C-l>"] = { primitives.visual_mode, "u", { desc = "downcase-region" } },
	-- set-goal-column unimplemented
	-- TODO: Implement
	["<C-x><C-o>"] = {
		primitives.insert_mode,
		custom_functionality.delete_blank_lines,
		{ desc = "delete-blank-lines" },
	},
	["<C-x><C-q>"] = {
		primitives.all_modes,
		primitives.ex_command("setlocal modifiable!"),
		{ desc = "read-only-mode" },
	},
	-- TODO: C-x C-r
	["<C-x><C-s>"] = { primitives.all_modes, primitives.ex_command("w"), { desc = "save-buffer" } },
	-- TODO: implement transpose-lines
	["<C-x><C-u>"] = { primitives.visual_mode, "U", { desc = "uppercase region" } },
	["<C-x><C-v>"] = {
		primitives.insert_mode,
		primitives.ex_command("bw") .. primitives.interactive_ex_command("e " .. get_cwd),
		{ desc = "find-alternate-file" },
	},
	["<C-x><C-w>"] = {
		primitives.insert_mode,
		primitives.interactive_ex_command("w " .. get_cwd),
		{ desc = "write-file" },
	},
	["<C-x><C-x>"] = {
		{
			primitives.insert_mode,
			function()
				local pos = marks.peek_mark_ring()
				marks.push_mark_ring()
				vim.api.nvim_win_set_pos(0, pos)
			end,
			{ desc = "exchange-point-and-mark" },
		},
		{ primitives.visual_mode, "o", { desc = "exchange-point-and-mark" } },
	},
	-- TODO: Theoretically, there is a prefix arg
	["<C-x><Space>"] = { primitives.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	-- set-selective-display unimplemented
	-- TODO: Abbrevs
	["<C-x>'"] = { primitives.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	-- TODO: Kmacros
	["<C-x>("] = { primitives.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	["<C-x>)"] = { primitives.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	["<C-x>*"] = { primitives.editing_modes, "<C-r>=", { desc = "calc-dispatch" } },
	-- balance-windows unimplemented
	-- shrink-window-if-larger-than-buffer unimplemented
	-- TODO: set-fill-prefix
	["<C-x>0"] = { primitives.all_modes, primitives.ex_command("quit"), { desc = "delete-window" } },
	["<C-x>1"] = { primitives.all_modes, primitives.ex_command("only"), { desc = "delete-other-windows" } },
	["<C-x>2"] = {
		primitives.navigation_modes,
		uarg.format_count(primitives.ex_command("%dbelow split")),
		{ desc = "split-window-below", expr = true },
	},
	["<C-x>3"] = {
		primitives.navigation_modes,
		uarg.format_count(primitives.ex_command("%drightb vsplit")),
		{ desc = "split-window-right", expr = true },
	},
	-- comment-set-column unimplemented
	["<C-x><"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.pass_count(function(count)
				count = count or (vim.api.nvim_win_get_width(0) - 2)
				local formatstr = ""
				if count < 0 then
					formatstr = "%dzh"
				elseif count > 0 then
					formatstr = "%dzl"
				else
					return ""
				end
				return string.format(normal(formatstr), math.abs(count))
			end)
		end,
		{ desc = "scroll-left", expr = true },
	}),
	-- what-cursor-position unimplemented
	["<C-x>>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.pass_count(function(count)
				count = count or (vim.api.nvim_win_get_width(0) - 2)
				local formatstr = ""
				if count < 0 then
					formatstr = "%dzl"
				elseif count > 0 then
					formatstr = "%dzh"
				else
					return ""
				end
				return string.format(normal(formatstr), math.abs(count))
			end)
		end,
		{ desc = "scroll-right", expr = true },
	}),
	["<C-x>^"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-w>+"), { opposite = normal("%d<C-w>-") })
		end,
		{ desc = "enlarge-window", expr = true },
	}),
	["<C-x>`"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.prefix_argument(uarg.format_count(normal("%d]q"), { opposite = "%d[q" }), normal("[Q"))
		end,
		{ desc = "next-error", expr = true },
	}),
	["<C-x>b"] = { primitives.insert_mode, primitives.interactive_ex_command("b "), { desc = "switch-to-buffer" } },
	["<C-x>d"] = { primitives.insert_mode, primitives.interactive_ex_command("e " .. get_cwd), { desc = "dired" } },
	["<C-x>h"] = {
		primitives.insert_mode,
		uarg.sequence(primitives.normal_from_insert("G$"), primitives.visual_from_insert("gg0")),
		{ desc = "mark-whole-buffer", expr = true },
	},
	["<C-x>i"] = {
		primitives.insert_mode,
		primitives.interactive_ex_command("read " .. get_cwd),
		{ desc = "insert-file" },
	},
	["<C-x>k"] = { primitives.all_modes, primitives.ex_command("bw"), { desc = "kill-buffer" } },
	-- count-lines-page unimplemented
	["<C-x>o"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.repeat_times(normal("<C-w>w"), { opposite = normal("<C-w>p") })
		end,
		{ desc = "other-window", expr = true },
	}),
	["<C-x>s"] = { primitives.all_modes, primitives.ex_command("wa"), { desc = "save-some-buffers" } },
	["<C-x>z"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return normal(".")
		end,
		{ desc = "repeat" },
	}),
	["<C-x>{"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-w><"), { opposite = normal("%d<C-w>>") })
		end,
		{ desc = "shrink-window-horizontally", expr = true },
	}),
	["<C-x>}"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-w>>"), { opposite = normal("%d<C-w><") })
		end,
		{ desc = "enlarge-window-horizontally", expr = true },
	}),
	-- TODO: C-x C-+, etc. mode
	-- TODO: Test
	["<C-x><C-;>"] = {
		primitives.insert_mode,
		uarg.format_count(
			primitives.normal_from_insert("%dgcc"),
			{ opposite = primitives.normal_from_insert("V%dkgc") }
		),
		{ desc = "comment-line", expr = true },
	},

	-- default-indent-new-line unimplemented
	["<C-M-o>"] = {
		primitives.insert_mode,
		custom_functionality.move_rest_of_line_down,
		{ desc = "split-line" },
	},
	["<C-M-r>"] = {
		{ primitives.insert_mode, primitives.normal_from_insert("?", ""), { desc = "isearch-backward-regexp" } },
		{ primitives.visual_mode, "?", { desc = "isearch-backward-regexp" } },
		{ primitives.command_mode, "<C-t>", { desc = "isearch-backward-regexp" } },
	},
	["<C-M-s>"] = {
		{ primitives.insert_mode, primitives.normal_from_insert("/", ""), { desc = "isearch-forward-regexp" } },
		{ primitives.visual_mode, "/", { desc = "isearch-forward-regexp" } },
		{ primitives.command_mode, "<C-g>", { desc = "isearch-forward-regexp" } },
	},
	["<C-M-v>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.sequence(
				select_other_window(normal),
				"<PageDown>",
				select_other_window(normal, { reverse = true })
			)
		end,
		{ desc = "scroll-other-window", expr = true },
	}),
	-- append-next-kill unimplemented
	-- indent-region unimplemented
	["<M-!>"] = { primitives.insert_mode, primitives.interactive_ex_command("!"), { desc = "shell-command" } },
	["<M-%>"] = {
		primitives.navigation_modes,
		primitives.interactive_ex_command("%s///c", "<Left><Left><Left>"),
		{ desc = "query-replace" },
	},
	["<M-&>"] = {
		primitives.insert_mode,
		primitives.interactive_ex_command("term "),
		{ desc = "async-shell-command" },
	},
	-- eval-expression unimplemented
	-- commend-dwim unimplemented
	-- count-words-region unimplemented
	["<M->>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function()
			return uarg.pass_count(function(count)
				count = count or 0
				return string.format(
					primitives.ex_command("go %d"),
					math.max(util.clamp(10 - count, 0, 10) / 10 * vim.fn.wordcount().bytes, 1)
				)
			end)
		end,
		{ desc = "end-of-buffer", expr = true },
	}),
	-- mark-word unimplemented
	["<M-a>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d(", "i"), { opposite = normal("%d)", "a") })
		end,
		{ desc = "backward-sentence", expr = true },
	}),
	["<M-b>"] = {
		primitives.input_modes,
		uarg.repeat_times("<C-Left>", { opposite = "<C-Right>" }),
		{ desc = "backward-word", expr = true },
	},
	["<M-c>"] = primitives.normal_bindings({
		primitives.editing_modes,
		function(normal)
			return uarg.repeat_times(normal("guevUw", "a"), { opposite = normal("vbguvUge") })
		end,
		{ desc = "capitalize-word", expr = true },
	}),
	["<M-d>"] = primitives.normal_bindings({
		primitives.editing_modes,
		function(normal)
			return uarg.format_count(normal("%dde"), { opposite = normal("v%dbd") })
		end,
		{ desc = "kill-word", expr = true },
	}),
	["<M-e>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d)", "a"), { opposite = normal("%d(", "i") })
		end,
		{ desc = "forward-sentence", expr = true },
	}),
	["<M-f>"] = {
		primitives.input_modes,
		uarg.repeat_times("<C-Right>", { opposite = "<C-Left>" }),
		{ desc = "forward-word", expr = true },
	},
	["<M-h>"] = {
		primitives.insert_mode,
		uarg.format_count(primitives.visual_from_insert("%d)o"), { opposite = primitives.visual_from_insert("%d(o") }),
		{ desc = "mark-paragraph", expr = true },
	},
	["<M-k>"] = {
		primitives.insert_mode,
		uarg.format_count(primitives.normal_from_insert("%dd)"), { opposite = primitives.normal_from_insert("v%d(d") }),
		{ desc = "kill-sentence", expr = true },
	},
	["<M-l>"] = primitives.normal_bindings({
		primitives.editing_modes,
		function(normal)
			return uarg.format_count(normal("%dguw"), { opposite = normal("v%dbgu`]") })
		end,
		{ desc = "downcase-word", expr = true },
	}),
	["<M-m>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return normal("^")
		end,
		{ desc = "back-to-indentation" },
	}),
	-- TODO: M-r is C-l but with H M L instead of zt zz zb
	-- TODO: transpose-words
	["<M-u>"] = primitives.normal_bindings({
		primitives.editing_modes,
		function(normal)
			return uarg.format_count(normal("%dgUw"), { opposite = normal("v%dbgU`]") })
		end,
		{ desc = "upcase-word", expr = true },
	}),
	-- TODO: Inaccurate
	["<M-v>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function()
			return uarg.repeat_times("<PageDown>", { opposite = "<PageUp>" })
		end,
		{ desc = "scroll-down-command", expr = true },
	}),
	["<M-w>"] = {
		primitives.visual_mode,
		"y",
		{ desc = "kill-ring-save" },
	},
	-- TODO: M-y
	-- TODO: Not quite correct. Emacs' version also goes to new lines
	["<M-z>"] = {
		primitives.insert_mode,
		input_handling.consume_inputstream(function(char, state)
			local action = uarg.format_count("kill-ring-save" .. char, { opposite = "v%dF" .. char .. "d" })()
			vim.cmd.normal(action, char)
			if not state.read_char then
				state.read_char = true
				return true
			else
				return false
			end
		end),
		{ desc = "zap-to-char" },
	},
	["<M-{>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d{", "i"), { opposite = normal("%d}", "a") })
		end,
		{ desc = "backward-paragraph", expr = true },
	}),
	-- TODO: Inaccurate
	["<C-u><M-|>"] = {
		primitives.visual_mode,
		primitives.interactive_ex_command("!"),
		{ desc = "filter region through a shell command" },
	},
	["<M-}>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d}", "a"), { opposite = normal("%d{", "i") })
		end,
		{ desc = "forward-paragraph", expr = true },
	}),
	-- TODO: not-modified
	-- recenter-other-window, scroll-other-window-down unimplemented
	["<C-M-%>"] = {
		primitives.navigation_modes,
		primitives.interactive_ex_command("%s///c", "<Left><Left><Left>"),
		{ desc = "query-replace-regexp" },
	},

	-- XXX: Ended off at isearch-forward-symbol-at-point

	-- Motion
	["<M-<>"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function()
			return uarg.pass_count(function(count)
				count = count or 0
				return string.format(
					primitives.ex_command("go %d"),
					math.max(util.clamp(count, 0, 10) / 10 * vim.fn.wordcount().bytes, 1)
				)
			end)
		end,
		{ desc = "go to buffer beggining", expr = true },
	}),
	["<M-g>g"] = {
		primitives.navigation_modes,
		uarg.format_count(primitives.ex_command("%d"), { default = prompts.prompt_count }),
		{ desc = "goto line", expr = true },
	},
	["<M-g>c"] = {
		primitives.navigation_modes,
		uarg.format_count(primitives.ex_command("go %d"), { default = prompts.prompt_count }),
		{ desc = "goto char", expr = true },
	},

	-- Killing and Deleting
	["<Bs>"] = {
		primitives.editing_modes,
		uarg.repeat_times("<Bs>", { opposite = "<Del>" }),
		{ desc = "kill character forward", expr = true },
	},
	["<M-Bs>"] = primitives.normal_bindings({
		primitives.editing_modes,
		function(normal)
			return uarg.format_count(normal("v%dbd"), { opposite = normal("%dde") })
		end,
		{ desc = "kill word backward", expr = true },
	}),
	["<C-x><Bs>"] = {
		primitives.insert_mode,
		uarg.format_count(primitives.normal_from_insert("v%d(d"), { opposite = primitives.normal_from_insert("%dd)") }),
		{ desc = "kill sentence backward", expr = true },
	},

	-- Marking
	["<M-@>"] = {
		primitives.insert_mode,
		uarg.format_count(primitives.visual_from_insert("%deo"), { opposite = primitives.visual_from_insert("%dbo") }),
		{ desc = "set mark words away", expr = true },
	},

	-- Query Replace

	-- Multiple Windows
	["<C-x>4b"] = {
		primitives.insert_mode,
		uarg.sequence(select_other_window(primitives.normal_from_insert), primitives.interactive_ex_command("e ")),
		{ desc = "select buffer in other window", expr = true },
	},
	["<C-x>4d"] = primitives.normal_bindings({
		primitives.navigation_modes,
		function(normal)
			return uarg.sequence(select_other_window(normal), primitives.ex_command("e ."))
		end,
		{ desc = "run Dired in other window", expr = true },
	}),
	["<C-x>4."] = {
		primitives.insert_mode,
		uarg.sequence(select_other_window(primitives.normal_from_insert), primitives.interactive_ex_command("tag ")),
		{ desc = "find tag in other window", expr = true },
	},

	-- Formatting
	["<Tab>"] = {
		{ primitives.insert_mode, primitives.normal_from_insert("=="), { desc = "indent current line" } },
		{ primitives.visual_mode, "=", { desc = "indent region" } },
	},
	["<C-M-\\>"] = { primitives.visual_mode, "=", { desc = "indent region" } },
	["<M-^>"] = {
		primitives.insert_mode,
		uarg.prefix_argument("<Up>" .. primitives.normal_from_insert("J"), "J"),
		{ desc = "join line with previous (with arg, next)", expr = true },
	},
	["<C-x>f"] = {
		primitives.insert_mode,
		custom_functionality.set_fill_column,
		{ desc = "set fill column to arg" },
	},

	-- Case Change

	-- Buffers

	-- Transposing
	["<M-t>"] = { primitives.editing_modes, custom_functionality.transpose_words, { desc = "transpose words" } },
	["<C-x><C-t>"] = { primitives.editing_modes, custom_functionality.transpose_lines, { desc = "transpose lines" } },

	-- Spelling Check
	["<M-$>"] = {
		primitives.insert_mode,
		primitives.normal_from_insert("z="),
		{ desc = "check spelling of current word" },
	},

	-- Tags
	["<M-.>"] = { primitives.insert_mode, primitives.interactive_ex_command("tag "), { desc = "find a tag" } },

	-- Shells

	-- Miscellaneous
}

-- For lua
M.lisp_interaction_mode_bindings = {}

-- array-mode
-- completion-mode
-- diff-mode
-- ido-mode
-- abbrev-mode
-- artist-mode
-- cua-mode

M.tab_bar_mode = {
	["<C-S-Tab>"] = { primitives.all_modes, primitives.ex_command("tabprevious"), { desc = "tab-previous" } },
	["<C-Tab>"] = { primitives.all_modes, primitives.ex_command("tabnext"), { desc = "tab-next" } },
}

-- TODO: Apply Equivalent keys and shift selection as a post-processing step

local equivalence_classes = {
	{ "<C-@>", "<C-Space>" },
	{ "<C-_>", "<C-/>", "<C-x>u" },
	{ "<C-->", "<M-->", "<C-M-->" },
	{ "<C-0>", "<M-0>", "<C-M-0>" },
	{ "<C-1>", "<M-1>", "<C-M-1>" },
	{ "<C-2>", "<M-2>", "<C-M-2>" },
	{ "<C-3>", "<M-3>", "<C-M-3>" },
	{ "<C-4>", "<M-4>", "<C-M-4>" },
	{ "<C-5>", "<M-5>", "<C-M-5>" },
	{ "<C-6>", "<M-6>", "<C-M-6>" },
	{ "<C-7>", "<M-7>", "<C-M-7>" },
	{ "<C-8>", "<M-8>", "<C-M-8>" },
	{ "<C-9>", "<M-9>", "<C-M-9>" },
	{ "<C-?>", "<C-M-?>" },
	{ "<C-x><C-@>", "<C-x><C-Space>" },
	{ "<C-z>", "<C-x><C-z>" },
	{ "<C-x>'", "<C-x>a'", "<C-x>ae" },
	{ "<C-x>(", "<C-x><C-k><C-s>", "<C-x><C-k>s" },
}

-- TODO: Also do this for other lists
for _, ec in ipairs(equivalence_classes) do
	local reference = nil
	for _, key in ipairs(ec) do
		if M.global_bindings[key] then
			reference = M.global_bindings[key]
			break
		end
	end
	for _, key in ipairs(ec) do
		M.global_bindings[key] = reference
	end
end

return M
