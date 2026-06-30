local M = {}

local util = require("eclectic.common.util")
local prims = require("eclectic.common.primitives")

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
			res = res .. prims.ex_command("new")
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

	["<C-@>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
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
	["<C-a>"] = prims.bindings(prims.normal, {
		prims.nonterminal_modes,
		-- Has to be this way since a failed h/j/k/l cancels the command
		function()
			return uarg.pass_count(function(count)
				count = (count or 1) - 1
				return "<Home>" .. string.rep(util.ternary(count > 0, "<Down>", "<Up>"), math.abs(count))
			end)
		end,
		{ desc = "move-beggining-of-line", expr = true },
	}),
	["<C-b>"] = {
		prims.nonterminal_modes,
		uarg.repeat_times("<Left>", { opposite = "<Right>" }),
		{ desc = "backward-char", expr = true },
	},
	["<C-d>"] = {
		prims.editing_modes,
		uarg.repeat_times("<Del>", { opposite = "<Bs>" }),
		{ desc = "delete-char", expr = true },
	},
	["<C-e>"] = prims.bindings(prims.normal, {
		prims.nonterminal_modes,
		-- Has to be this way since a failed h/j/k/l cancels the command
		function()
			return uarg.pass_count(function(count)
				count = (count or 1) - 1
				return "<End>" .. string.rep(util.ternary(count > 0, "<Down>", "<Up>"), math.abs(count))
			end)
		end,
		{ desc = "move-end-of-line", expr = true },
	}),
	["<C-f>"] = {
		prims.nonterminal_modes,
		uarg.repeat_times("<Right>", { opposite = "<Left>" }),
		{ desc = "forward-char", expr = true },
	},
	-- TODO: Special interaction with searching and other stuff
	["<C-g>"] = { prims.command_mode, "<Esc>", { desc = "keyboard-quit" } },
	-- C-j is already a neovim binding
	["<C-k>"] = {
		{
			prims.insert_mode,
			uarg.format_count(
				prims.normal.from_insert("%dD"),
				{ opposite = prims.normal.from_insert("v0%dkd"), zero = prims.normal.from_insert("v0d") }
			),
			{ desc = "kill-line", expr = true },
		},
		{
			prims.command_mode,
			uarg.format_count(
				prims.normal.from_command("D"),
				{ opposite = prims.normal.from_command("v0d"), zero = prims.normal.from_command("v0d") }
			),
			{ desc = "kill-line", expr = true },
		},
	},
	["<C-l>"] = {
		prims.navigation_modes,
		custom_functionality.recenter_top_bottom,
		{ desc = "recenter-top-bottom" },
	},
	["<C-n>"] = {
		prims.nonterminal_modes,
		uarg.repeat_times("<Down>", { opposite = "<Up>" }),
		{ desc = "next-line", expr = true },
	},
	-- TODO: Fill prefix
	["<C-o>"] = {
		prims.insert_mode,
		uarg.repeat_times(prims.normal.from_insert("O")),
		{ desc = "next-line", expr = true },
	},
	["<C-p>"] = {
		prims.nonterminal_modes,
		uarg.repeat_times("<Up>", { opposite = "<Down>" }),
		{ desc = "previous-line", expr = true },
	},
	-- C-q exists already
	["<C-r>"] = {
		{ prims.normal_mode, prims.normal.from_normal("?"), { desc = "isearch-backward" } },
		{ prims.insert_mode, prims.normal.from_insert("?"), { desc = "isearch-backward" } },
		{ prims.select_mode, prims.normal.from_select("?"), { desc = "isearch-backward" } },
		{ prims.visual_mode, prims.normal.from_visual("?"), { desc = "isearch-backward" } },
		{ prims.command_mode, "<C-t>", { desc = "isearch-backward" } },
	},
	["<C-s>"] = {
		{ prims.normal_mode, prims.normal.from_normal("/"), { desc = "isearch-forward" } },
		{ prims.insert_mode, prims.normal.from_insert("/"), { desc = "isearch-forward" } },
		{ prims.select_mode, prims.normal.from_select("/"), { desc = "isearch-forward" } },
		{ prims.visual_mode, prims.normal.from_visual("/"), { desc = "isearch-forward" } },
		{ prims.command_mode, "<C-g>", { desc = "isearch-forward" } },
	},
	-- FIXME: Doesnt work
	-- ["<C-t>"] = prims.bindings(prims.normal, {
	-- 	prims.editing_modes,
	-- 	function(normal)
	-- 		return uarg.format_count(normal("x<Left>%s<Right>p"), { opposite = normal("x<Left>%s<Left>p") })
	-- 	end,
	-- 	{ desc = "transpose-chars", expr = true },
	-- }),
	["<C-u>"] = {
		prims.nonterminal_modes,
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
	["<C-v>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-e>"), { opposite = normal("%d<C-y>"), default_cmd = normal("<C-d>") })
		end,
		{ desc = "scroll-up-command", expr = true },
	}),
	-- TODO: Test
	["<C-w>"] = {
		{
			prims.insert_mode,
			function()
				vim.cmd.normal("v")
				marks.jump_mark_ring()
				vim.cmd.normal("d")
			end,
			{ desc = "kill-region" },
		},
		{ prims.visual_mode, "d", { desc = "kill-region" } },
	},
	["<C-y>"] = {
		{
			prims.insert_mode,
			uarg.prefix_argument(prims.normal.from_insert("p", "a"), prims.normal.from_insert("p", "`[i")),
			{ desc = "yank", expr = true },
		},
		-- TODO: Maybe implement this under "custom functionality"
		{
			prims.command_mode,
			uarg.prefix_argument(
				uarg.format_count("<C-r>%d", { zero = "<C-r>0", default = 0 }),
				uarg.sequence(function()
					local unnammed_register = vim.fn.getreg('"')
					string.gsub(unnammed_register, "\n", " ")
					vim.fn.setreg('"', unnammed_register)
					-- Command buffer has own set of marks
				end, prims.normal.from_command("mzi<Left><Esc>p`z"))
			),
			{ desc = "yank", expr = true },
		},
	},
	["<C-z>"] = { prims.nonterminal_modes, prims.ex_command("suspend"), { desc = "suspend-frame" } },
	-- C-\ unimplemented
	-- C-] unimplemented
	["<C-_>"] = prims.bindings(prims.normal, {
		prims.nonterminal_modes,
		function(normal)
			return uarg.format_count(normal("%du"))
		end,
		{ desc = "undo", expr = true },
	}),
	["<C-->"] = {
		prims.nonterminal_modes,
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
		prims.nonterminal_modes,
		function()
			uarg.add_digit(0)
		end,
		{ desc = "digit-argument" },
	},
	["<C-1>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(1)
		end,
		{ desc = "digit-argument" },
	},
	["<C-2>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(2)
		end,
		{ desc = "digit-argument" },
	},
	["<C-3>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(3)
		end,
		{ desc = "digit-argument" },
	},
	["<C-4>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(4)
		end,
		{ desc = "digit-argument" },
	},
	["<C-5>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(5)
		end,
		{ desc = "digit-argument" },
	},
	["<C-6>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(6)
		end,
		{ desc = "digit-argument" },
	},
	["<C-7>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(7)
		end,
		{ desc = "digit-argument" },
	},
	["<C-8>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(8)
		end,
		{ desc = "digit-argument" },
	},
	["<C-9>"] = {
		prims.nonterminal_modes,
		function()
			uarg.add_digit(9)
		end,
		{ desc = "digit-argument" },
	},
	["<C-?>"] = prims.bindings(prims.normal, {
		prims.nonterminal_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-r>"))
		end,
		{ desc = "undo-redo", expr = true },
	}),
	-- TODO: test
	["<C-S-Bs>"] = {
		prims.insert_mode,
		uarg.format_count(
			prims.normal.from_insert("%ddd"),
			{ opposite = prims.normal.from_insert("V%dkd"), zero = prims.normal.from_insert("0d$") }
		),
		{ desc = "kill-whole-line", expr = true },
	},
	["<C-Bs>"] = prims.bindings(prims.normal, {
		prims.editing_modes,
		function(normal)
			return uarg.format_count(normal("v%dbd", "a"), { opposite = normal("%dde") })
		end,
		{ desc = "backward-kill-word", expr = true },
	}),

	-- TODO: Find appropriate help pages for all of these
	["<C-h>a"] = {
		prims.insert_mode,
		prims.interactive_ex_command.from_insert("help "),
		{ desc = "about-emacs" },
	},

	["<C-x><C-@>"] = {
		prims.navigation_modes,
		function()
			marks.jump_global_mark_ring()
			marks.pop_global_mark_ring()
		end,
		{ desc = "pop-global-mark" },
	},
	["<C-x><C-b>"] = { prims.all_modes, prims.ex_command("ls"), { desc = "list-buffers" } },
	["<C-x><C-c>"] = {
		prims.all_modes,
		uarg.prefix_argument(prims.ex_command("qa"), prims.ex_command("wqa")),
		{ desc = "save-buffers-kill-terminal", expr = true },
	},
	["<C-x><C-d>"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("e " .. get_cwd)
		end,
		{ desc = "list-directory" },
	}),
	["<C-x><C-f>"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("e " .. get_cwd)
		end,
		{ desc = "find-file" },
	}),
	-- TODO: incorrect. is technically its own modes
	["<C-x><Tab>"] = {
		prims.visual_mode,
		uarg.sequence(uarg.repeat_times(">gv", { opposite = "<gv" }), "v"),
		{ desc = "indent region rigidly arg columns", expr = true },
	},
	["<C-x><C-j>"] = {
		prims.all_modes,
		prims.ex_command("e ."),
		{ desc = "dired-jump" },
	},
	["<C-x><C-l>"] = { prims.visual_mode, "u", { desc = "downcase-region" } },
	-- set-goal-column unimplemented
	-- TODO: Implement
	["<C-x><C-o>"] = {
		prims.insert_mode,
		custom_functionality.delete_blank_lines,
		{ desc = "delete-blank-lines" },
	},
	["<C-x><C-q>"] = {
		prims.all_modes,
		prims.ex_command("setlocal modifiable!"),
		{ desc = "read-only-mode" },
	},
	-- TODO: C-x C-r
	["<C-x><C-s>"] = { prims.all_modes, prims.ex_command("write"), { desc = "save-buffer" } },
	-- TODO: implement transpose-lines
	["<C-x><C-u>"] = { prims.visual_mode, "U", { desc = "uppercase region" } },
	["<C-x><C-v>"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return prims.ex_command("bw") .. iex("e " .. get_cwd)
		end,
		{ desc = "find-alternate-file" },
	}),
	["<C-x><C-w>"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("w " .. get_cwd)
		end,
		{ desc = "write-file" },
	}),
	["<C-x><C-x>"] = {
		{
			prims.insert_mode,
			function()
				local pos = marks.peek_mark_ring()
				marks.push_mark_ring()
				vim.api.nvim_win_set_pos(0, pos)
			end,
			{ desc = "exchange-point-and-mark" },
		},
		{ prims.visual_mode, "o", { desc = "exchange-point-and-mark" } },
	},
	-- TODO: Theoretically, there is a prefix arg
	["<C-x><Space>"] = { prims.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	-- set-selective-display unimplemented
	-- TODO: Abbrevs
	["<C-x>'"] = { prims.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	-- TODO: Kmacros
	["<C-x>("] = { prims.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	["<C-x>)"] = { prims.visual_mode, "<C-v>", { desc = "rectangle-mark-mode" } },
	["<C-x>*"] = { prims.editing_modes, "<C-r>=", { desc = "calc-dispatch" } },
	-- balance-windows unimplemented
	-- shrink-window-if-larger-than-buffer unimplemented
	-- TODO: set-fill-prefix
	["<C-x>0"] = { prims.all_modes, prims.ex_command("quit"), { desc = "delete-window" } },
	["<C-x>1"] = { prims.all_modes, prims.ex_command("only"), { desc = "delete-other-windows" } },
	["<C-x>2"] = {
		prims.all_modes,
		uarg.format_count(prims.ex_command("%dsplit"), { default_cmd = prims.ex_command("split") }),
		{ desc = "split-window-below", expr = true },
	},
	["<C-x>3"] = {
		prims.all_modes,
		uarg.format_count(prims.ex_command("%dvsplit"), { default_cmd = prims.ex_command("vsplit") }),
		{ desc = "split-window-right", expr = true },
	},
	-- comment-set-column unimplemented
	["<C-x><"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
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
	["<C-x>>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
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
	["<C-x>^"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-w>+"), { opposite = normal("%d<C-w>-") })
		end,
		{ desc = "enlarge-window", expr = true },
	}),
	["<C-x>`"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.prefix_argument(uarg.format_count(normal("%d]q"), { opposite = "%d[q" }), normal("[Q"))
		end,
		{ desc = "next-error", expr = true },
	}),
	["<C-x>b"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("b ")
		end,
		{ desc = "switch-to-buffer" },
	}),
	["<C-x>d"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("e " .. get_cwd)
		end,
		{ desc = "dired" },
	}),
	["<C-x>h"] = {
		prims.insert_mode,
		uarg.sequence(prims.normal.from_insert("G$"), prims.interactive_visual.from_insert("gg0")),
		{ desc = "mark-whole-buffer", expr = true },
	},
	["<C-x>i"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("read " .. get_cwd)
		end,
		{ desc = "insert-file" },
	}),
	["<C-x>k"] = { prims.all_modes, prims.ex_command("bw"), { desc = "kill-buffer" } },
	-- count-lines-page unimplemented
	["<C-x>o"] = prims.bindings(prims.normal, {
		prims.all_modes,
		function(normal)
			return uarg.repeat_times(normal("<C-w>w"), { opposite = normal("<C-w>p") })
		end,
		{ desc = "other-window", expr = true },
	}),
	["<C-x>s"] = { prims.all_modes, prims.ex_command("wa"), { desc = "save-some-buffers" } },
	["<C-x>z"] = prims.bindings(prims.normal, {
		prims.editing_modes,
		function(normal)
			return normal(".")
		end,
		{ desc = "repeat" },
	}),
	["<C-x>{"] = prims.bindings(prims.normal, {
		prims.all_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-w><"), { opposite = normal("%d<C-w>>") })
		end,
		{ desc = "shrink-window-horizontally", expr = true },
	}),
	["<C-x>}"] = prims.bindings(prims.normal, {
		prims.all_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-w>>"), { opposite = normal("%d<C-w><") })
		end,
		{ desc = "enlarge-window-horizontally", expr = true },
	}),
	-- TODO: C-x C-+, etc. mode
	-- TODO: Test
	["<C-x><C-;>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%dgcc"), { opposite = normal("V%dkgc") })
		end,
		{ desc = "comment-line", expr = true },
	}),

	-- default-indent-new-line unimplemented
	["<C-M-o>"] = {
		prims.insert_mode,
		custom_functionality.move_rest_of_line_down,
		{ desc = "split-line" },
	},
	["<C-M-v>"] = prims.bindings(prims.normal, {
		prims.all_modes,
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
	["<M-!>"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("!")
		end,
		{ desc = "shell-command" },
	}),
	["<M-%>"] = prims.bindings(prims.interactive_ex_command, {
		prims.navigation_modes,
		function(iex)
			return iex("%s///c", "<Left><Left><Left>")
		end,
		{ desc = "query-replace" },
	}),
	["<M-&>"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("term ")
		end,
		{ desc = "async-shell-command" },
	}),
	-- eval-expression unimplemented
	-- commend-dwim unimplemented
	-- count-words-region unimplemented
	["<M->>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		uarg.pass_count(function(count)
			count = count or 0
			return string.format(
				prims.ex_command("go %d"),
				math.max(util.clamp(10 - count, 0, 10) / 10 * vim.fn.wordcount().bytes, 1)
			)
		end),
		{ desc = "end-of-buffer", expr = true },
	}),
	-- mark-word unimplemented
	["<M-a>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d(", "i"), { opposite = normal("%d)", "a") })
		end,
		{ desc = "backward-sentence", expr = true },
	}),
	["<M-b>"] = {
		prims.nonterminal_modes,
		uarg.repeat_times("<C-Left>", { opposite = "<C-Right>" }),
		{ desc = "backward-word", expr = true },
	},
	-- TODO: Make more solid
	-- ["<M-c>"] = prims.bindings(prims.normal, {
	-- 	prims.editing_modes,
	-- 	function(normal)
	-- 		return uarg.repeat_times(normal("guevUw", "a"), { opposite = normal("vbguvUge") })
	-- 	end,
	-- 	{ desc = "capitalize-word", expr = true },
	-- }),
	["<M-d>"] = prims.bindings(prims.normal, {
		prims.editing_modes,
		function(normal)
			return uarg.format_count(normal("%dde"), { opposite = normal("v%dbd") })
		end,
		{ desc = "kill-word", expr = true },
	}),
	["<M-e>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d)", "a"), { opposite = normal("%d(", "i") })
		end,
		{ desc = "forward-sentence", expr = true },
	}),
	["<M-f>"] = {
		prims.nonterminal_modes,
		uarg.repeat_times("<C-Right>", { opposite = "<C-Left>" }),
		{ desc = "forward-word", expr = true },
	},
	["<M-h>"] = prims.bindings(prims.interactive_visual, {
		prims.navigation_modes,
		function(iv)
			return uarg.format_count(iv("%d)o"), { opposite = iv("%d(o") })
		end,
		{ desc = "mark-paragraph", expr = true },
	}),
	["<M-k>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%dd)"), { opposite = normal("v%d(d") })
		end,
		{ desc = "kill-sentence", expr = true },
	}),
	["<M-l>"] = prims.bindings(prims.normal, {
		prims.editing_modes,
		function(normal)
			return uarg.format_count(normal("%dguw"), { opposite = normal("v%dbgu`]") })
		end,
		{ desc = "downcase-word", expr = true },
	}),
	["<M-m>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return normal("^")
		end,
		{ desc = "back-to-indentation" },
	}),
	-- TODO: M-r is C-l but with H M L instead of zt zz zb
	-- TODO: transpose-words
	["<M-u>"] = prims.bindings(prims.normal, {
		prims.editing_modes,
		function(normal)
			return uarg.format_count(normal("%dgUw"), { opposite = normal("v%dbgU`]") })
		end,
		{ desc = "upcase-word", expr = true },
	}),
	-- TODO: Inaccurate
	["<M-v>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d<C-y>"), { opposite = normal("%d<C-e>"), default_cmd = normal("<C-u>") })
		end,
		{ desc = "scroll-down-command", expr = true },
	}),
	["<M-w>"] = {
		prims.visual_mode,
		"y",
		{ desc = "kill-ring-save" },
	},
	["<M-x>"] = prims.bindings(prims.interactive_ex_command, {
		prims.all_modes,
		function(iex)
			return iex("")
		end,
		{ desc = "execute-extended-command" },
	}),
	-- TODO: M-y
	-- TODO: Not quite correct. Emacs' version also goes to new lines
	["<M-z>"] = {
		prims.insert_mode,
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
	["<M-{>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d{", "i"), { opposite = normal("%d}", "a") })
		end,
		{ desc = "backward-paragraph", expr = true },
	}),
	-- TODO: Inaccurate
	["<C-u><M-|>"] = {
		prims.visual_mode,
		prims.interactive_ex_command.from_insert("!"),
		{ desc = "filter region through a shell command" },
	},
	["<M-}>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.format_count(normal("%d}", "a"), { opposite = normal("%d{", "i") })
		end,
		{ desc = "forward-paragraph", expr = true },
	}),
	-- TODO: not-modified
	-- recenter-other-window, scroll-other-window-down unimplemented
	["<C-M-%>"] = {
		prims.navigation_modes,
		prims.interactive_ex_command.from_insert("%s///c", "<Left><Left><Left>"),
		{ desc = "query-replace-regexp" },
	},

	-- XXX: Ended off at isearch-forward-symbol-at-point

	-- Motion
	["<M-<>"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		uarg.pass_count(function(count)
			count = count or 0
			return string.format(
				prims.ex_command("go %d"),
				math.max(util.clamp(count, 0, 10) / 10 * vim.fn.wordcount().bytes, 1)
			)
		end),
		{ desc = "go to buffer beggining", expr = true },
	}),
	["<M-g>g"] = {
		prims.navigation_modes,
		uarg.format_count(prims.ex_command("%d"), { default = prompts.prompt_count }),
		{ desc = "goto line", expr = true },
	},
	["<M-g>c"] = {
		prims.navigation_modes,
		uarg.format_count(prims.ex_command("go %d"), { default = prompts.prompt_count }),
		{ desc = "goto char", expr = true },
	},

	-- Killing and Deleting
	["<Bs>"] = {
		prims.editing_modes,
		uarg.repeat_times("<Bs>", { opposite = "<Del>" }),
		{ desc = "kill character forward", expr = true },
	},
	["<C-x><Bs>"] = {
		prims.insert_mode,
		uarg.format_count(prims.normal.from_insert("v%d(d"), { opposite = prims.normal.from_insert("%dd)") }),
		{ desc = "kill sentence backward", expr = true },
	},

	-- Marking
	["<M-@>"] = {
		prims.insert_mode,
		uarg.format_count(
			prims.interactive_visual.from_insert("%deo"),
			{ opposite = prims.interactive_visual.from_insert("%dbo") }
		),
		{ desc = "set mark words away", expr = true },
	},

	-- Query Replace

	-- Multiple Windows
	["<C-x>4b"] = {
		prims.insert_mode,
		uarg.sequence(select_other_window(prims.normal.from_insert), prims.interactive_ex_command.from_insert("e ")),
		{ desc = "select buffer in other window", expr = true },
	},
	["<C-x>4d"] = prims.bindings(prims.normal, {
		prims.navigation_modes,
		function(normal)
			return uarg.sequence(select_other_window(normal), prims.ex_command("e ."))
		end,
		{ desc = "run Dired in other window", expr = true },
	}),
	["<C-x>4."] = {
		prims.insert_mode,
		uarg.sequence(select_other_window(prims.normal.from_insert), prims.interactive_ex_command.from_insert("tag ")),
		{ desc = "find tag in other window", expr = true },
	},

	-- Formatting
	["<Tab>"] = {
		{ prims.insert_mode, prims.normal.from_insert("=="), { desc = "indent current line" } },
		{ prims.visual_mode, "=", { desc = "indent region" } },
	},
	["<C-M-\\>"] = { prims.visual_mode, "=", { desc = "indent region" } },
	["<M-^>"] = {
		prims.insert_mode,
		uarg.prefix_argument("<Up>" .. prims.normal.from_insert("J"), "J"),
		{ desc = "join line with previous (with arg, next)", expr = true },
	},
	["<C-x>f"] = {
		prims.insert_mode,
		custom_functionality.set_fill_column,
		{ desc = "set fill column to arg" },
	},

	-- Case Change

	-- Buffers

	-- Transposing
	["<M-t>"] = { prims.editing_modes, custom_functionality.transpose_words, { desc = "transpose words" } },
	["<C-x><C-t>"] = { prims.editing_modes, custom_functionality.transpose_lines, { desc = "transpose lines" } },

	-- Spelling Check
	["<M-$>"] = {
		prims.insert_mode,
		prims.normal.from_insert("z="),
		{ desc = "check spelling of current word" },
	},

	-- Tags
	["<M-.>"] = {
		prims.insert_mode,
		prims.interactive_ex_command.from_insert("tag "),
		{ desc = "find a tag" },
	},

	-- Shells

	-- Miscellaneous
}

-- For lua

-- array-mode
-- completion-mode
-- diff-mode
-- ido-mode
-- abbrev-mode
-- artist-mode
-- cua-mode


M.tab_bar_mode = {
	["<C-S-Tab>"] = { prims.all_modes, prims.ex_command("tabprevious"), { desc = "tab-previous" } },
	["<C-Tab>"] = { prims.all_modes, prims.ex_command("tabnext"), { desc = "tab-next" } },
}

M.move_text = {
	["<M-Down>"] = prims.bindings(prims.visual, {
		prims.navigation_modes,
		function(visual)
			return uarg.pass_count(function(count)
				count = count or 1
				if count < 0 then
					return string.format(visual(":m '<%d<CR>") .. visual("=", "gv"), count - 1)
				elseif count > 0 then
					return string.format(visual(":m '>+%d<CR>") .. visual("=", "gv"), count)
				else
					return ""
				end
			end)
		end,
		{ desc = "move-line-down", expr = true },
	}),
	["<M-Up>"] = prims.bindings(prims.visual, {
		prims.navigation_modes,
		function(visual)
			return uarg.pass_count(function(count)
				count = count or -1
				if count < 0 then
					return string.format(visual(":m '<%d<CR>") .. visual("=", "gv"), count - 1)
				elseif count > 0 then
					return string.format(visual(":m '>+%d<CR>") .. visual("=", "gv"), count)
				else
					return ""
				end
			end)
		end,
		{ desc = "move-line-up", expr = true },
	}),
}

-- TODO: Apply Equivalent keys and shift selection as a post-processing step

local equivalence_classes = {
	{ "<C-@>", "<C-Space>" },
	{ "<C-r>", "<C-M-r>" },
	{ "<C-s>", "<C-M-s>" },
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
	{ "<C-Bs>", "<M-Bs>" },
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
