local M = {}

local util = require("eclectic.util")
local uarg = require("eclectic.emacs.universal_argument")
local stateful = require("eclectic.emacs.stateful")
local custom_functionality = require("eclectic.emacs.custom_functionality")

-- Not possible: Help, Emacs Lisp interpreter, S-Expressions, jump over function, support for frames
-- TODO: Dont know what it does Incremental Search M-p, Motion C-x [ (pages), Motion C-x <,
-- Killing and Deleting C-w (region), Killing and Deleting M-y, Query Replace recursive edit,
-- Multiple windows C-x 4 b (other window), Formatting M-;, Formatting M-^, Formatting C-x C-o (around point)
-- Formatting M-q, Formatting C-x f, Formatting C-x ., Rectangles, Abbrevs, Registers
--
-- CTRL-F for found concepts
-- Hard: Keyboard macros

-- TODO: Use insert_mode instead of both_modes where appropriate

-- TODO: Numeric arguments, stateful operations

-- TODO: Could reimplement emacs functionalities using vim.ui.input. Maybe this is a NON-GOAL

-- TODO: Replace all occurences of sexp with treesitter node (Requires newest neovim version, update README)
-- https://github.com/neovim/neovim/commit/72d3a57f270fdca5e592dcf2e4b7c3b00549c05e

-- TODO: Eliminate all hidden assumptions. Make code more explicit (move opposite into kwargs). Improve error handling.

-- TODO: Investigate flickering in e.g. M-f

function M.generate_bindings(normal_command, ex_command, interactive_ex_command)
	-- FIXME: Huge Flaw: Cant go into normal mode while in command mode
	-- Yes we can. "<C-f>{command}<C-c><Cmd>redraw<CR>"

	-- TODO: Rename modes
	local line_editing = { "i", "c" }
	local text_editing = "i"
	local incremental_command = "c"
	local select_mode = "x"

	local get_cwd = "<C-r>=getcwd()<CR>"

	-- Extracted from GNU Emcas Reference Card (for version 30)
	-- and the help page for all key bindings
	return {
		-- Leaving Emacs
		{ text_editing, "<C-z>", normal_command("<C-z>"), { desc = "iconify Emacs (or suspend it in terminal)" } },
		{
			line_editing,
			"<C-x><C-c>",
			uarg.pass_flag(function(flag)
				return ex_command(flag and "wqa" or "qa")
			end),
			{ desc = "exit Emacs permanently", expr = true },
		},

		-- Files
		{ text_editing, "<C-x><C-f>", interactive_ex_command("e " .. get_cwd), { desc = "read a file into Emacs" } },
		{ line_editing, "<C-x><C-s>", ex_command("w"), { desc = "save a file back to disk" } },
		{ line_editing, "<C-x>s", ex_command("wa"), { desc = "save all files" } },
		{
			text_editing,
			"<C-x>i",
			interactive_ex_command("read " .. get_cwd),
			{ desc = "insert contents of another file into this buffer" },
		},
		{
			text_editing,
			"<C-x><C-v>",
			ex_command("bw") .. interactive_ex_command("e " .. get_cwd),
			{ desc = "replace this file with the file you really want" },
		},
		{
			text_editing,
			"<C-x><C-w>",
			interactive_ex_command("w " .. get_cwd),
			{ desc = "write buffer to a specified file" },
		},
		{
			line_editing,
			"<C-x><C-q>",
			ex_command("set modifiable!"),
			{ desc = "toggle read-only status of buffer" },
		},

		-- Getting Help
		{ line_editing, "<C-h>", ex_command("help"), { desc = "show help" } },
		{ line_editing, "<C-h>t", ex_command("Tutor"), { desc = "show tutorial" } },
		{ text_editing, "<C-h>a", interactive_ex_command("help "), { desc = "show tutorial" } },
		{ text_editing, "<C-h>k", interactive_ex_command("help "), { desc = "show tutorial" } },
		{ text_editing, "<C-h>f", interactive_ex_command("help "), { desc = "show tutorial" } },
		{ text_editing, "<C-h>m", interactive_ex_command("help "), { desc = "show tutorial" } },

		-- Error Recovery
		{ incremental_command, "<C-g>", "<Esc>", { desc = "abort partially typed or executing command" } },
		{
			text_editing,
			{ "<C-x>u", "<C-x>_", "<C-x>/" },
			uarg.format_count(normal_command("%du"), uarg.positive_count),
			{ desc = "undo an unwanted change", expr = true },
		},

		-- Incremental Search
		{ text_editing, "<C-s>", normal_command("/"), { desc = "search forward" } },
		{ incremental_command, "<C-s>", "<C-g>", { desc = "search forward" } },
		{ text_editing, "<C-r>", normal_command("?"), { desc = "search backward" } },
		{ incremental_command, "<C-r>", "<C-t>", { desc = "search backward" } },
		{ text_editing, "<C-M-s>", normal_command("/"), { desc = "regular expression search" } },
		{ incremental_command, "<C-M-s>", "<C-g>", { desc = "regular expression search" } },
		{ text_editing, "<C-M-r>", normal_command("?"), { desc = "reverse regular expression search" } },
		{ incremental_command, "<C-M-r>", "<C-t>", { desc = "reverse regular expression search" } },

		-- Motion
		{
			line_editing,
			"<C-b>",
			uarg.repeat_times("<Left>", uarg.nonzero_count, "<Right>"),
			{ desc = "move over character backward", expr = true },
		},
		{
			line_editing,
			"<C-f>",
			uarg.repeat_times("<Right>", uarg.nonzero_count, "<Left>"),
			{ desc = "move over character forward", expr = true },
		},
		{
			line_editing,
			"<M-b>",
			uarg.repeat_times("<C-Left>", uarg.nonzero_count, "<C-Right>"),
			{ desc = "move over character backward", expr = true },
		},
		{
			line_editing,
			"<M-f>",
			uarg.repeat_times("<C-Right>", uarg.nonzero_count, "<C-Left>"),
			{ desc = "move over character forward", expr = true },
		},
		{
			line_editing,
			"<C-p>",
			uarg.repeat_times("<Down>", uarg.nonzero_count, "<Up>"),
			{ desc = "move over line backward", expr = true },
		},
		{
			line_editing,
			"<C-n>",
			uarg.repeat_times("<Up>", uarg.nonzero_count, "<Down>"),
			{ desc = "move over line forward", expr = true },
		},
		{
			line_editing,
			"<C-a>",
			uarg.repeat_times("<Home>", uarg.nonzero_count, "<End>"),
			{ desc = "go to line beginning", expr = true },
		},
		{
			line_editing,
			"<C-e>",
			uarg.repeat_times("<End>", uarg.nonzero_count, "<Home>"),
			{ desc = "go to line end", expr = true },
		},
		{
			text_editing,
			"<M-a>",
			uarg.format_count(normal_command("("), uarg.nonzero_count, normal_command(")")),
			{ desc = "move over sentence backward", expr = true },
		},
		{
			text_editing,
			"<M-e>",
			uarg.format_count(normal_command(")"), uarg.nonzero_count, normal_command("(")),
			{ desc = "move over sentence forward", expr = true },
		},
		{
			text_editing,
			"<M-{>",
			uarg.format_count(normal_command("("), uarg.nonzero_count, normal_command(")")),
			{ desc = "move over paragraph backward", expr = true },
		},
		{
			text_editing,
			"<M-}>",
			uarg.format_count(normal_command("("), uarg.nonzero_count, normal_command(")")),
			{ desc = "move over paragraph forward", expr = true },
		},
		{
			text_editing,
			"<M-<>",
			uarg.pass_count(function(count)
				return string.format(ex_command("go %d"), math.min(count, 10) / 10 * vim.fn.wordcount().bytes)
			end, uarg.nonnegative_count),
			{ desc = "go to buffer beggining", expr = true },
		},
		{
			text_editing,
			"<M->>",
			uarg.pass_count(function(count)
				return string.format(ex_command("go %d"), math.max(10 - count, 0) / 10 * vim.fn.wordcount().bytes)
			end, uarg.nonnegative_count),
			{ desc = "go to buffer end", expr = true },
		},
		{
			text_editing,
			"<C-v>",
			uarg.repeat_times("<PageUp>", uarg.nonzero_count, "<PageDown>"),
			{ desc = "scroll to next screen", expr = true },
		},
		{
			text_editing,
			"<M-v>",
			uarg.repeat_times("<PageDown>", uarg.nonzero_count, "<PageUp>"),
			{ desc = "scroll to previous screen", expr = true },
		},
		{
			text_editing,
			"<C-l>",
			stateful.scroll_center_top_bottom,
			{ desc = "scroll current text to center, top, bottom", expr = true },
		},
		{ text_editing, "<M-g>g", custom_functionality.goto_line, { desc = "goto line" } },
		{ text_editing, "<M-g>c", custom_functionality.goto_char, { desc = "goto char" } },
		{ text_editing, "<M-m>", normal_command("^"), { desc = "back to indentation" } },

		-- Killing and Deleting
		-- TODO: Command mode needs a whole implementation of its own...
		{ line_editing, "<C-d>", "<Del>", { desc = "kill character forward" } },
		{ line_editing, { "<M-BS>", "<C-BS>" }, normal_command("db"), { desc = "kill word backward" } },
		{ line_editing, "<M-d>", normal_command("dw"), { desc = "kill word forward" } },
		{ line_editing, "<M-0><C-k>", normal_command("d0"), { desc = "kill to end of line backward" } },
		{ line_editing, "<C-k>", normal_command("D"), { desc = "kill to end of line forward" } },
		{ line_editing, "<C-x><BS>", normal_command("d("), { desc = "kill sentence backward" } },
		{ line_editing, "<M-k>", normal_command("d)"), { desc = "kill sentence forward" } },
		{ line_editing, "<M-z>", normal_command("df"), { desc = "kill through next occurence of" } },
		{ line_editing, "<C-y>", normal_command("p"), { desc = "yank back last thing killed" } },

		-- Marking
		{ line_editing, "<C-@>", normal_command("v"), { desc = "set mark here" } },
		{ line_editing, "<C-Space>", normal_command("v"), { desc = "set mark here" } },
		{ select_mode, "<C-x><C-x>", "o", { desc = "exchange point and mark" } },
		-- TODO: Implement marks correctly
		--  { insert_mode,"<M-@>",  numeric_argument.mark_words_away, { desc = "set mark words away" } },
		--  { insert_mode,"<M-h>",  numeric_argument.mark_paragraph, { desc = "mark paragraph" } },
		-- FIXME: Needs special treatment
		-- { text_editing, "<C-x>h", normal_commands("Gvgg0"), { desc = "mark entire buffer" } },

		-- Query Replace
		{
			text_editing,
			"<M-%>",

			interactive_ex_command("%s///c<Left><Left><Left>"),
			{ desc = "interactively replace a text string" },
		},

		-- Multiple Windows
		{ line_editing, "<C-x>1", normal_command("<C-w>o"), { desc = "delete all other windows" } },
		{ line_editing, "<C-x>2", normal_command("<C-w>s"), { desc = "split window, above and below" } },
		{ line_editing, "<C-x>0", normal_command("<C-w>q"), { desc = "delete this window" } },
		{ line_editing, "<C-x>3", normal_command("<C-w>v"), { desc = "split window, side by side" } },
		-- { line_editing, "<C-M-v>", normal_commands("<C-w>w<PageDown><C-w>pi"), { desc = "scroll other window" } },
		{ line_editing, "<C-x>o", normal_command("<C-w>w"), { desc = "switch cursor to another window" } },
		{ line_editing, "<C-x>^", normal_command("<C-w>+"), { desc = "grow window taller" } },
		{ line_editing, "<C-x>{", normal_command("<C-w><"), { desc = "shrink window narrower" } },
		{ line_editing, "<C-x>}", normal_command("<C-w>>"), { desc = "grow window wider" } },

		-- Formatting
		{ line_editing, "<C-x>}", normal_command("<C-w>>"), { desc = "grow window wider" } },
		-- FIXME:
		-- { text_editing, "<Tab>", normal_command("=="), { desc = "indent current line" } },
		{
			text_editing,
			"<C-M-o>",

			custom_functionality.move_rest_of_line_down,
			{ desc = "move rest of line vertically down" },
		},
		{
			line_editing,
			"<M-Space>",

			"<Space>",
			{ desc = "put exactly one space at point" },
		},

		-- Case Change
		{ line_editing, "<M-u>", normal_command("gUw"), { desc = "uppercase word" } },
		{ line_editing, "<M-l>", normal_command("guw"), { desc = "lowercase word" } },
		-- { line_editing, "<M-c>", normal_commands("guwvUi"), { desc = "lowercase word" } },

		-- Buffers
		{ line_editing, "<C-x>b", interactive_ex_command("b "), { desc = "select another buffer" } },
		{ line_editing, "<C-x><C-b>", ex_command("ls"), { desc = "list all buffers" } },
		{ line_editing, "<C-x>k", ex_command("bw"), { desc = "kill a buffer" } },

		-- Transposing
		{ line_editing, "<C-t>", custom_functionality.transpose_characters, { desc = "transpose characters" } },
		{ line_editing, "<M-t>", custom_functionality.transpose_words, { desc = "transpose words" } },
		{ line_editing, "<C-t>", custom_functionality.transpose_lines, { desc = "transpose lines" } },

		-- Spelling Check
		{ line_editing, "<M-$>", normal_command("z="), { desc = "check spelling of current word" } },

		-- Tags
		{ line_editing, "<M-.>", interactive_ex_command("tag "), { desc = "find a tag" } },

		-- Shells
		{ line_editing, "<M-!>", interactive_ex_command("!"), { desc = "execute a shell command" } },
		{
			line_editing,
			"<M-&>",
			interactive_ex_command("term "),
			{ desc = "execute a shell command asynchronously" },
		},

		-- Miscellaneous
		-- TODO: Implement
		{ line_editing, "<C-u>", custom_functionality.universal_argument, { desc = "numeric argument" } },
		-- TODO: Add negative count support
	}
end

return M
