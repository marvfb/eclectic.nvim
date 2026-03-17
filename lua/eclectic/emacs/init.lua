local M = {}

local util = require("eclectic.util")
local uarg = require("eclectic.emacs.universal_argument")
local stateful = require("eclectic.emacs.stateful")
local custom_functionality = require("eclectic.emacs.custom_functionality")

-- Dont wanna do: Help, Emacs Lisp interpreter, support for frames, pages, recursive edit, crazy emacs indentation, abbrevs (snippets)
-- TODO: Dont know how it works
-- Fill prefix

-- Maybe wanna do, but not worth the effort: Rectangles, Registers (Fun but not useful when compared to vim's equivalents)

-- TODO: Implement S-Expreesions, functions as a text object using treesitter

-- TODO: Replace all occurences of sexp with treesitter node (Requires newest neovim version, update README)
-- https://github.com/neovim/neovim/commit/72d3a57f270fdca5e592dcf2e4b7c3b00549c05e

-- TODO: Improve error handling.

-- TODO: Could make it into a hashmap again

-- TODO: Should definitely reduce redundancy

-- TODO: Add cursor movement (v) as an option
local editing_modes = { "i", "c" }
local insert_mode = "i"
local command_mode = "c"
local visual_mode = "x"

local function normal_from_insert(str, reenter_how)
	reenter_how = reenter_how or "i"
	return string.format("<Esc>%s" .. reenter_how, str)
end
local function normal_from_command(str, reenter_how)
	reenter_how = reenter_how or "i"
	return string.format("<C-f>%s" .. reenter_how .. "<C-c><Cmd>redraw<CR>", str)
end
local function ex_command(str)
	return string.format("<Cmd>%s<CR>", str)
end
local function interactive_ex_command(str, cursor_adjustment)
	return string.format("<C-o>:%s" .. (cursor_adjustment or ""), str)
end
local function visual_from_insert(str, enter_how)
	enter_how = enter_how or "v"
	return string.format("<C-o>" .. enter_how .. "%s", str)
end

local get_cwd = "<C-r>=getcwd()<CR>"
local select_other_window = function()
	local num_windows = #vim.api.nvim_tabpage_list_wins(0)
	local res = ""
	if num_windows < 2 then
		res = res .. ex_command("new")
	end
	return res .. normal_from_insert("<C-w>w")
end

-- Extracted from GNU Emcas Reference Card (for version 30)
-- and the help page for all key bindings
M.bindings = {
	-- Leaving Emacs
	{ editing_modes, "<C-z>", ex_command("suspend"), { desc = "iconify Emacs (or suspend it in terminal)" } },
	{
		editing_modes,
		"<C-x><C-c>",
		uarg.pass_flag(ex_command("qa"), ex_command("wqa")),
		{ desc = "exit Emacs permanently", expr = true },
	},

	-- Files
	{ insert_mode, "<C-x><C-f>", interactive_ex_command("e " .. get_cwd), { desc = "read a file into Emacs" } },
	{ editing_modes, "<C-x><C-s>", ex_command("w"), { desc = "save a file back to disk" } },
	{ editing_modes, "<C-x>s", ex_command("wa"), { desc = "save all files" } },
	{
		insert_mode,
		"<C-x>i",
		interactive_ex_command("read " .. get_cwd),
		{ desc = "insert contents of another file into this buffer" },
	},
	{
		insert_mode,
		"<C-x><C-v>",
		ex_command("bw") .. interactive_ex_command("e " .. get_cwd),
		{ desc = "replace this file with the file you really want" },
	},
	{
		insert_mode,
		"<C-x><C-w>",
		interactive_ex_command("w " .. get_cwd),
		{ desc = "write buffer to a specified file" },
	},
	{
		editing_modes,
		"<C-x><C-q>",
		ex_command("setlocal modifiable!"),
		{ desc = "toggle read-only status of buffer" },
	},

	-- Getting Help
	{ editing_modes, "<C-h>", ex_command("help"), { desc = "show help" } },
	{ editing_modes, "<C-h>t", ex_command("Tutor"), { desc = "show tutorial" } },
	{ insert_mode, "<C-h>a", interactive_ex_command("help "), { desc = "show tutorial" } },
	{ insert_mode, "<C-h>k", interactive_ex_command("help "), { desc = "show tutorial" } },
	{ insert_mode, "<C-h>f", interactive_ex_command("help "), { desc = "show tutorial" } },
	{ insert_mode, "<C-h>m", interactive_ex_command("help "), { desc = "show tutorial" } },

	-- Error Recovery
	{ command_mode, "<C-g>", "<Esc>", { desc = "abort partially typed or executing command" } },
	{
		insert_mode,
		{ "<C-x>u", "<C-x>_", "<C-x>/" },
		uarg.format_count(normal_from_insert("%du")),
		{ desc = "undo an unwanted change", expr = true },
	},

	-- Incremental Search
	{ insert_mode, "<C-s>", normal_from_insert("/", ""), { desc = "search forward" } },
	{ command_mode, "<C-s>", "<C-g>", { desc = "search forward" } },
	{ insert_mode, "<C-r>", normal_from_insert("?", ""), { desc = "search backward" } },
	{ command_mode, "<C-r>", "<C-t>", { desc = "search backward" } },
	{ insert_mode, "<C-M-s>", normal_from_insert("/", ""), { desc = "regular expression search" } },
	{ command_mode, "<C-M-s>", "<C-g>", { desc = "regular expression search" } },
	{ insert_mode, "<C-M-r>", normal_from_insert("?", ""), { desc = "reverse regular expression search" } },
	{ command_mode, "<C-M-r>", "<C-t>", { desc = "reverse regular expression search" } },

	-- Motion
	{
		editing_modes,
		"<C-b>",
		uarg.repeat_times("<Left>", { opposite = "<Right>" }),
		{ desc = "move over character backward", expr = true },
	},
	{
		editing_modes,
		"<C-f>",
		uarg.repeat_times("<Right>", { opposite = "<Left>" }),
		{ desc = "move over character forward", expr = true },
	},
	{
		editing_modes,
		"<M-b>",
		uarg.repeat_times("<C-Left>", { opposite = "<C-Right>" }),
		{ desc = "move over character backward", expr = true },
	},
	{
		editing_modes,
		"<M-f>",
		uarg.repeat_times("<C-Right>", { opposite = "<C-Left>" }),
		{ desc = "move over character forward", expr = true },
	},
	{
		editing_modes,
		"<C-p>",
		uarg.repeat_times("<Down>", { opposite = "<Up>" }),
		{ desc = "move over line backward", expr = true },
	},
	{
		editing_modes,
		"<C-n>",
		uarg.repeat_times("<Up>", { opposite = "<Down>" }),
		{ desc = "move over line forward", expr = true },
	},
	{
		insert_mode,
		"<C-a>",
		-- Has to be this way since a failed h/j/k/l cancels the command
		uarg.pass_count(function(count)
			count = (count or 0) - 1
			return "<Home>"
				.. string.rep("<Down>", math.max(count, 0) + 1)
				.. string.rep("<Up>", math.abs(math.min(count, 0)))
		end),
		-- uarg.repeat_times("<Home>", { opposite = "<End>" }),
		{ desc = "go to line beginning", expr = true },
	},
	{
		command_mode,
		"<C-a>",
		uarg.repeat_times("<Home>", { opposite = "<End>" }),
		{ desc = "go to line beginning", expr = true },
	},
	{
		insert_mode,
		"<C-e>",
		uarg.pass_count(function(count)
			count = (count or 0) - 1
			return "<End>"
				.. string.rep("<Down>", math.max(count, 0) + 1)
				.. string.rep("<Up>", math.abs(math.min(count, 0)))
		end),
		{ desc = "go to line end", expr = true },
	},
	{
		command_mode,
		"<C-e>",
		uarg.repeat_times("<End>", { opposite = "<Home>" }),
		{ desc = "go to line end", expr = true },
	},
	{
		insert_mode,
		"<M-a>",
		uarg.format_count(normal_from_insert("%d(", "i"), { opposite = normal_from_insert("%d)", "a") }),
		{ desc = "move over sentence backward", expr = true },
	},
	{
		insert_mode,
		"<M-e>",
		uarg.format_count(normal_from_insert("%d)", "a"), { opposite = normal_from_insert("%d(", "i") }),
		{ desc = "move over sentence forward", expr = true },
	},
	{
		insert_mode,
		"<M-{>",
		uarg.format_count(normal_from_insert("%d{", "i"), { opposite = normal_from_insert("%d}", "a") }),
		{ desc = "move over paragraph backward", expr = true },
	},
	{
		insert_mode,
		"<M-}>",
		uarg.format_count(normal_from_insert("%d}", "a"), { opposite = normal_from_insert("%d{", "i") }),
		{ desc = "move over paragraph forward", expr = true },
	},
	{
		insert_mode,
		"<M-<>",
		uarg.pass_count(function(count)
			count = count or 0
			return string.format(ex_command("go %d"), util.clamp(count, 0, 10) / 10 * vim.fn.wordcount().bytes)
		end),
		{ desc = "go to buffer beggining", expr = true },
	},
	{
		insert_mode,
		"<M->>",
		uarg.pass_count(function(count)
			count = count or 0
			return string.format(ex_command("go %d"), util.clamp(10 - count, 0, 10) / 10 * vim.fn.wordcount().bytes)
		end),
		{ desc = "go to buffer end", expr = true },
	},
	-- TODO: Could add flag here. Need combinators for that.
	{
		insert_mode,
		"<C-v>",
		uarg.repeat_times("<PageUp>", { opposite = "<PageDown>" }),
		{ desc = "scroll to next screen", expr = true },
	},
	{
		insert_mode,
		"<M-v>",
		uarg.repeat_times("<PageDown>", { opposite = "<PageUp>" }),
		{ desc = "scroll to previous screen", expr = true },
	},
	{
		insert_mode,
		"<C-x><",
		uarg.pass_count(function(count)
			count = count or (vim.api.nvim_win_get_width(0) - 2)
			local formatstr = ""
			if count < 0 then
				formatstr = "%dzh"
			elseif count > 0 then
				formatstr = "%dzl"
			else
				return ""
			end
			return string.format(normal_from_insert(formatstr), math.abs(count))
		end),
		{ desc = "scroll left", expr = true },
	},
	{
		insert_mode,
		"<C-x>>",
		uarg.pass_count(function(count)
			count = count or (vim.api.nvim_win_get_width(0) - 2)
			local formatstr = ""
			if count < 0 then
				formatstr = "%dzl"
			elseif count > 0 then
				formatstr = "%dzh"
			else
				return ""
			end
			return string.format(normal_from_insert(formatstr), math.abs(count))
		end),
		{ desc = "scroll right", expr = true },
	},
	{
		insert_mode,
		"<C-l>",
		stateful.scroll_center_top_bottom,
		{ desc = "scroll current text to center, top, bottom", expr = true },
	},
	{ insert_mode, "<M-g>g", custom_functionality.goto_line, { desc = "goto line" } },
	{ insert_mode, "<M-g>c", custom_functionality.goto_char, { desc = "goto char" } },
	{ insert_mode, "<M-m>", normal_from_insert("^"), { desc = "back to indentation" } },

	-- Killing and Deleting
	{
		editing_modes,
		"<Bs>",
		uarg.repeat_times("<Bs>", { opposite = "<Del>" }),
		{ desc = "kill character forward", expr = true },
	},
	{
		editing_modes,
		"<C-d>",
		uarg.repeat_times("<Del>", { opposite = "<Bs>" }),
		{ desc = "kill character forward", expr = true },
	},
	{
		insert_mode,
		{ "<M-Bs>", "<C-Bs>" },
		uarg.format_count(normal_from_insert("v%dbd"), { opposite = normal_from_insert("%dde") }),
		{ desc = "kill word backward", expr = true },
	},
	{
		command_mode,
		{ "<M-Bs>", "<C-Bs>" },
		uarg.format_count(normal_from_command("v%dbd"), { opposite = normal_from_command("%dde") }),
		{ desc = "kill word backward", expr = true },
	},
	{
		insert_mode,
		"<M-d>",
		uarg.format_count(normal_from_insert("%dde"), { opposite = normal_from_insert("v%dbd") }),
		{ desc = "kill word forward", expr = true },
	},
	{
		command_mode,
		"<M-d>",
		uarg.format_count(normal_from_command("%dde"), { opposite = normal_from_command("v%dbd") }),
		{ desc = "kill word forward", expr = true },
	},
	{
		insert_mode,
		"<C-k>",
		uarg.format_count(
			normal_from_insert("%dD"),
			{ opposite = normal_from_insert("v0%dkd"), zero = normal_from_insert("v0d") }
		),
		{ desc = "kill to end of line forward", expr = true },
	},
	{
		command_mode,
		"<C-k>",
		uarg.format_count(
			normal_from_command("D"),
			{ opposite = normal_from_insert("v0d"), zero = normal_from_insert("v0d") }
		),
		{ desc = "kill to end of line forward", expr = true },
	},
	{
		insert_mode,
		"<C-x><Bs>",
		uarg.format_count(normal_from_insert("v%d(d"), { opposite = normal_from_insert("%dd)") }),
		{ desc = "kill sentence backward", expr = true },
	},
	{
		insert_mode,
		"<M-k>",
		uarg.format_count(normal_from_insert("%dd)"), { opposite = normal_from_insert("v%d(d") }),
		{ desc = "kill sentence forward", expr = true },
	},
	{
		visual_mode,
		"<C-w>",
		"d",
		{ desc = "kill region" },
	},
	{
		visual_mode,
		"<M-w>",
		"y",
		{ desc = "copy region to kill ring" },
	},
	{
		insert_mode,
		"<M-z>",
		custom_functionality.zap_to_char,
		{ desc = "kill through next occurence of" },
	},
	{
		insert_mode,
		"<C-y>",
		uarg.pass_flag(normal_from_insert("p", "a"), normal_from_insert("gp", "i")),
		{ desc = "yank back last thing killed", expr = true },
	},
	{
		command_mode,
		"<C-y>",
		-- uarg.pass_flag(normal_from_command("o<Esc>VPkVGJ", "a"), normal_from_command("o<Esc>VPkVGJ", "i")),
		custom_functionality.yank_commandline,
		{ desc = "yank back last thing killed" },
	},

	-- Marking
	{ insert_mode, { "<C-@>", "<C-Space>" }, visual_from_insert(""), { desc = "set mark here" } },
	{ visual_mode, { "<C-@>", "<C-Space>" }, "v", { desc = "set mark here" } },
	{ visual_mode, "<C-x><C-x>", "o", { desc = "exchange point and mark" } },
	{
		insert_mode,
		"<M-@>",
		uarg.format_count(visual_from_insert("%deo"), { opposite = visual_from_insert("%dbo") }),
		{ desc = "set mark words away", expr = true },
	},
	{
		insert_mode,
		"<M-h>",
		uarg.format_count(visual_from_insert("%d)o"), { opposite = visual_from_insert("%d(o") }),
		{ desc = "mark paragraph", expr = true },
	},
	{
		insert_mode,
		"<C-x>h",
		uarg.sequence(normal_from_insert("G$"), visual_from_insert("gg0")),
		{ desc = "mark entire buffer", expr = true },
	},

	-- Query Replace
	{
		insert_mode,
		"<M-%>",
		interactive_ex_command("%s///c", "<Left><Left><Left>"),
		{ desc = "interactively replace a text string" },
	},

	-- Multiple Windows
	{ insert_mode, "<C-x>1", normal_from_insert("<C-w>o"), { desc = "delete all other windows" } },
	{
		insert_mode,
		"<C-x>2",
		uarg.format_count(ex_command("%dbelow split")),
		{ desc = "split window, above and below", expr = true },
	},
	{ insert_mode, "<C-x>0", normal_from_insert("<C-w>q"), { desc = "delete this window" } },
	{
		insert_mode,
		"<C-x>3",
		uarg.format_count(ex_command("%drightb vsplit")),
		{ desc = "split window, side by side", expr = true },
	},
	{
		insert_mode,
		"<C-M-v>",
		uarg.sequence(select_other_window, "<PageDown>"),
		{ desc = "scroll other window", expr = true },
	},
	{
		insert_mode,
		"<C-x>o",
		uarg.repeat_times(normal_from_insert("<C-w>w"), { opposite = "<C-w>p" }),
		{ desc = "switch cursor to another window", expr = true },
	},
	{
		insert_mode,
		-- I know. But I didnt bother.
		{ "<C-x>4b", "<C-x>4<C-o>", "<C-x>4f", "<C-x>4r" },
		uarg.sequence(select_other_window, interactive_ex_command("e ")),
		{ desc = "select buffer in other window", expr = true },
	},
	{
		insert_mode,
		"<C-x>4d",
		uarg.sequence(select_other_window, ex_command("e .")),
		{ desc = "run Dired in other window", expr = true },
	},
	{
		insert_mode,
		"<C-x>4.",
		uarg.sequence(select_other_window, interactive_ex_command("tag ")),
		{ desc = "find tag in other window", expr = true },
	},
	{
		insert_mode,
		"<C-x>^",
		uarg.format_count(normal_from_insert("%d<C-w>+"), { opposite = normal_from_insert("%d<C-w>-") }),
		{ desc = "grow window taller", expr = true },
	},
	{
		insert_mode,
		"<C-x>{",
		uarg.format_count(normal_from_insert("%d<C-w><"), { opposite = normal_from_insert("%d<C-w>>") }),
		{ desc = "shrink window narrower", expr = true },
	},
	{
		insert_mode,
		"<C-x>}",
		uarg.format_count(normal_from_insert("%d<C-w>>"), { opposite = normal_from_insert("%d<C-w><") }),
		{ desc = "grow window wider", expr = true },
	},

	-- Formatting
	{ insert_mode, "<Tab>", normal_from_insert("=="), { desc = "indent current line" } },
	{ visual_mode, "<C-M-\\>", "=", { desc = "indent region" } },
	{
		visual_mode,
		"<C-x><Tab>",
		uarg.sequence(uarg.repeat_times(">gv", { opposite = "<gv" }), "v"),
		{ desc = "indent region rigidly arg columns", expr = true },
	},
	{
		insert_mode,
		"<C-x><C-o>",
		custom_functionality.delete_blank_lines,
		{ desc = "delete blank lines around point" },
	},
	{
		insert_mode,
		"<C-M-o>",
		custom_functionality.move_rest_of_line_down,
		{ desc = "move rest of line vertically down" },
	},
	{
		insert_mode,
		"<M-^>",
		uarg.pass_flag("<Up>" .. normal_from_insert("J"), "J"),
		{ desc = "move rest of line vertically down", expr = true },
	},
	{
		insert_mode,
		"<C-x>f",
		custom_functionality.set_fill_column,
		{ desc = "set fill column to arg" },
	},

	-- Case Change
	{
		insert_mode,
		"<M-u>",
		uarg.format_count(normal_from_insert("%dgUw"), { opposite = normal_from_insert("v%dbgU`]") }),
		{ desc = "uppercase word", expr = true },
	},
	{
		command_mode,
		"<M-u>",
		uarg.format_count(normal_from_command("%dgUw"), { opposite = normal_from_command("v%dbgU`]") }),
		{ desc = "uppercase word", expr = true },
	},
	{
		insert_mode,
		"<M-u>",
		uarg.format_count(normal_from_insert("%dguw"), { opposite = normal_from_insert("v%dbgu`]") }),
		{ desc = "uppercase word", expr = true },
	},
	{
		command_mode,
		"<M-u>",
		uarg.format_count(normal_from_command("%dguw"), { opposite = normal_from_command("v%dbgu`]") }),
		{ desc = "uppercase word", expr = true },
	},
	-- TODO:
	-- { line_editing, "<M-c>", normal_commands("guwvUi"), { desc = "lowercase word" } },
	{ visual_mode, "<C-x><C-u>", "U", { desc = "uppercase region" } },
	{ visual_mode, "<C-x><C-l>", "u", { desc = "lowercase region" } },

	-- Buffers
	{ insert_mode, "<C-x>b", interactive_ex_command("b "), { desc = "select another buffer" } },
	{ editing_modes, "<C-x><C-b>", ex_command("ls"), { desc = "list all buffers" } },
	{ editing_modes, "<C-x>k", ex_command("bw"), { desc = "kill a buffer" } },

	-- Transposing
	{ editing_modes, "<C-t>", custom_functionality.transpose_characters, { desc = "transpose characters" } },
	{ editing_modes, "<M-t>", custom_functionality.transpose_words, { desc = "transpose words" } },
	{ editing_modes, "<C-t>", custom_functionality.transpose_lines, { desc = "transpose lines" } },

	-- Spelling Check
	{ insert_mode, "<M-$>", normal_from_insert("z="), { desc = "check spelling of current word" } },
	{ command_mode, "<M-$>", normal_from_command("z="), { desc = "check spelling of current word" } },

	-- Tags
	{ insert_mode, "<M-.>", interactive_ex_command("tag "), { desc = "find a tag" } },

	-- Shells
	{ insert_mode, "<M-!>", interactive_ex_command("!"), { desc = "execute a shell command" } },
	{
		insert_mode,
		"<M-&>",
		interactive_ex_command("term "),
		{ desc = "execute a shell command asynchronously" },
	},
	{ visual_mode, "<C-u><M-|>", interactive_ex_command("!"), { desc = "filter region through a shell command" } },

	-- Miscellaneous
	{ editing_modes, "<C-u>", custom_functionality.universal_argument, { desc = "numeric argument" } },
	{
		editing_modes,
		{ "<C-->", "<M-->", "<C-M-->" },
		custom_functionality.negative_argument,
		{ desc = "negative-argument" },
	},
}

return M
