local M = {}

local special_functionality = require("eclectic.special_functionality")
local stateful = require("eclectic.stateful")
local numeric_argument = require("eclectic.numeric_argument")
local stateful_with_numeric_argument = require("eclectic.stateful_with_numeric_argument")

local default_config = {
	-- Keep vim defaults
	-- If a bool is given, all vim defaults are preserved
	-- If a list is given, only those listed are preserved
	keep = false,
	-- Use readline-flavored emacs bindings
	-- Table of differences
	-- Binding Emacs            Readline
	-- <C-w>   ..               Delete word backwards
	-- <C-u>   Numeric argument Delete line backwards
	-- TODO: Complete table
	readline_flavored = true,
	-- "i" for insert
	-- "c" for command
	-- "!" for both (supposedly)
	modes = { "i", "c" },
	-- The mode you are dropped in after a command was executed
	-- For vim users, it can be disorienting being put into
	-- insert mode after a command, so it is made configurable here
	mode_after_command = "i",
	-- You can add your personal bindings here
	personal_bindings = {
		-- TODO: Add more
		{ { "i", "c" }, "<C-<>", "<C-o><<", { desc = "deindent line" } },
		{ { "i", "c" }, "<C->>", "<C-o>>>", { desc = "indent line" } },
	},
}

local both_modes = { "i", "c" }
local insert_mode = "i"
local command_mode = "c"
local visual_mode = "x"
local normal_command = "<C-o>"
-- TODO: Needs to be adapted for different end modes
local normal_commands = "<Esc>"
local ex_command = "<C-o><Cmd>"
local interactive_ex_command = "<C-o>:"
local get_cwd = "<C-r>=getcwd()<CR>"
local start_of_buffer = "<Esc>gg0i"
local end_of_buffer = "<Esc>G$a"

-- Extracted from GNU Emcas Reference Card (for version 30)
local emacs_insert_bindings = {
	-- Leaving Emacs
	{ both_modes, "<C-z>", normal_command .. "<C-z>", { desc = "iconify Emacs (or suspend it in terminal)" } },
	{ both_modes, "<C-x><C-c>", ex_command .. "qa<CR>", { desc = "exit Emacs permanently" } },

	-- Files
	{ both_modes, "<C-x><C-f>", interactive_ex_command .. "e " .. get_cwd, { desc = "read a file into Emacs" } },
	{ both_modes, "<C-x><C-s>", ex_command .. "w<CR>", { desc = "save a file back to disk" } },
	{ both_modes, "<C-x>s", ex_command .. "wa<CR>", { desc = "save all files" } },
	{
		both_modes,
		"<C-x>i",
		interactive_ex_command .. "read " .. get_cwd,
		{ desc = "insert contents of another file into this buffer" },
	},
	{
		both_modes,
		"<C-x><C-v>",
		interactive_ex_command .. "e " .. get_cwd,
		{ desc = "replace this file with the file you really want" },
	},
	{
		both_modes,
		"<C-x><C-w>",
		interactive_ex_command .. "w " .. get_cwd,
		{ desc = "write buffer to a specified file" },
	},
	{ both_modes, "<C-x><C-q>", ex_command .. "set modifiable!<CR>", { desc = "toggle read-only status of buffer" } },

	-- Getting Help
	{ both_modes, "<C-h>", ex_command .. "help<CR>", { desc = "show help" } },
	{ both_modes, "<C-h>t", ex_command .. "Tutor<CR>", { desc = "show tutorial" } },
	{
		both_modes,
		{ "<C-h>a", "<C-h>k", "<C-h>f", "<C-h>m" },
		interactive_ex_command .. "help ",
		{ desc = "show tutorial" },
	},

	-- Error Recovery
	-- FIXME: Interaction with searching
	{ command_mode, "<C-g>", "<Esc>", { desc = "abort partially typed or executing command" } },
	{ both_modes, { "<C-x>u", "<C-_>", "<C-/>" }, normal_command .. "u", { desc = "undo an unwanted change" } },
	{ both_modes, "<C-l>", normal_command .. "<C-l>", { desc = "undo an unwanted change" } },

	-- Incremental Search
	{ insert_mode, "<C-s>", normal_command .. "/", { desc = "search forward" } },
	{ command_mode, "<C-s>", "<C-g>", { desc = "search forward" } },
	{ insert_mode, "<C-r>", normal_command .. "?", { desc = "search backward" } },
	{ command_mode, "<C-r>", "<C-t>", { desc = "search backward" } },
	{ insert_mode, "<C-M-s>", normal_command .. "/", { desc = "regular expression search" } },
	{ command_mode, "<C-M-s>", "<C-g>", { desc = "regular expression search" } },
	{ insert_mode, "<C-M-r>", normal_command .. "?", { desc = "reverse regular expression search" } },
	{ command_mode, "<C-M-r>", "<C-t>", { desc = "reverse regular expression search" } },

	-- Motion
	{ both_modes, "<C-b>", "<Left>", { desc = "move over character backward" } },
	{ both_modes, "<C-f>", "<Right>", { desc = "move over character forward" } },
	{ both_modes, "<M-b>", normal_command .. "b", { desc = "move over character backward" } },
	{ both_modes, "<M-f>", normal_command .. "e" .. "<Right>", { desc = "move over character forward" } },
	{ both_modes, "<C-p>", "<Up>", { desc = "move over line backward" } },
	{ both_modes, "<C-n>", "<Down>", { desc = "move over line forward" } },
	{ both_modes, "<C-a>", "<Home>", { desc = "go to line beginning" } },
	{ both_modes, "<C-e>", "<End>", { desc = "go to line end" } },
	{ both_modes, "<M-a>", normal_command .. "(", { desc = "move over sentence backward" } },
	{ both_modes, "<M-e>", normal_command .. ")", { desc = "move over sentence forward" } },
	{ both_modes, "<M-{>", normal_command .. "{", { desc = "move over paragraph backward" } },
	{ both_modes, "<M-}>", normal_command .. "}", { desc = "move over paragraph forward" } },
	{ both_modes, "<M-<>", start_of_buffer, { desc = "go to buffer beggining" } },
	{ both_modes, "<M->>", end_of_buffer, { desc = "go to buffer end" } },
	{ both_modes, "<C-v>", "<PageUp>", { desc = "scroll to next screen" } },
	{ both_modes, "<M-v>", "<PageDown>", { desc = "scroll to previous screen" } },
	{ both_modes, "<C-l>", stateful.scroll_center_top_bottom, { desc = "scroll current line to center, top, bottom" } },
	{ both_modes, "<M-g>g", interactive_ex_command, { desc = "goto line" } },
	{ both_modes, "<M-g>g", interactive_ex_command .. "go ", { desc = "goto char" } },
	{ both_modes, "<M-m>", normal_command .. "^", { desc = "back to indentation" } },

	-- Killing and Deleting
	{ both_modes, "<C-d>", "<Del>", { desc = "kill character forward" } },
	{ both_modes, { "<M-BS>", "<C-BS>" }, normal_command .. "db", { desc = "kill word backward" } },
	{ both_modes, "<M-d>", normal_command .. "dw", { desc = "kill word forward" } },
	{ both_modes, "<M-0><C-k>", normal_command .. "d0", { desc = "kill to end of line backward" } },
	{ both_modes, "<C-k>", normal_command .. "D", { desc = "kill to end of line forward" } },
	{ both_modes, "<C-x><BS>", normal_command .. "d(", { desc = "kill sentence backward" } },
	{ both_modes, "<M-k>", normal_command .. "d)", { desc = "kill sentence forward" } },
	{ both_modes, "<M-z>", normal_command .. "df", { desc = "kill through next occurence of" } },
	{ both_modes, "<C-y>", normal_command .. "p", { desc = "yank back last thing killed" } },

	-- Marking
	{ both_modes, { "<C-@>", "<C-Space>" }, normal_command .. "v", { desc = "set mark here" } },
	{ visual_mode, "<C-x><C-x>", "o", { desc = "exchange point and mark" } },
	{ insert_mode, "<M-@>", numeric_argument.mark_words_away, { desc = "set mark words away" } },
	{ insert_mode, "<M-h>", stateful_with_numeric_argument.mark_paragraph, { desc = "mark paragraph" } },
	{ insert_mode, "<C-x>h", end_of_buffer .. normal_command .. "vgg0", { desc = "mark entire buffer" } },

	-- Query Replace
	{
		insert_mode,
		"<M-%>",
		interactive_ex_command .. "%s///c<Left><Left><Left>",
		{ desc = "interactively replace a text string" },
	},

	-- Multiple Windows
	{ both_modes, "<C-x>1", normal_command .. "<C-w>o", { desc = "delete all other windows" } },
	{ both_modes, "<C-x>2", normal_command .. "<C-w>s", { desc = "split window, above and below" } },
	{ both_modes, "<C-x>0", normal_command .. "<C-w>q", { desc = "delete this window" } },
	{ both_modes, "<C-x>3", normal_command .. "<C-w>v", { desc = "split window, side by side" } },
	{ both_modes, "<C-M-v>", normal_commands .. "<C-w>w<PageDown><C-w>pi", { desc = "scroll other window" } },
	{ both_modes, "<C-x>o", normal_command .. "<C-w>w", { desc = "switch cursor to another window" } },
	{ both_modes, "<C-x>^", normal_command .. "<C-w>+", { desc = "grow window taller" } },
	{ both_modes, "<C-x>{", normal_command .. "<C-w><", { desc = "shrink window narrower" } },
	{ both_modes, "<C-x>}", normal_command .. "<C-w>>", { desc = "grow window wider" } },

	-- Formatting
	{ both_modes, "<C-x>}", normal_command .. "<C-w>>", { desc = "grow window wider" } },
	{ insert_mode, "<Tab>", normal_command .. "==", { desc = "indent current line" } },
	{
		insert_mode,
		"<C-M-o>",
		special_functionality.move_rest_of_line_down,
		{ desc = "move rest of line vertically down" },
	},
	{
		both_modes,
		"<M-Space>",
		"<Space>",
		{ desc = "put exactly one space at point" },
	},

	-- Case Change
	{ both_modes, "<M-u>", normal_command .. "gUw", { desc = "uppercase word" } },
	{ both_modes, "<M-l>", normal_command .. "guw", { desc = "lowercase word" } },
	{ both_modes, "<M-c>", normal_commands .. "guwvUi", { desc = "lowercase word" } },
}

-- Not possible: Help, Emacs Lisp interpreter, S-Expressions, jump over function, support for frames
-- TODO: Dont know what it does Incremental Search M-p, Motion C-x [ (pages), Motion C-x <,
-- Killing and Deleting C-w (region), Killing and Deleting M-y, Query Replace recursive edit,
-- Multiple windows C-x 4 b (other window), Formatting M-;, Formatting M-^, Formatting C-x C-o (around point)
-- Formatting M-q, Formatting C-x f, Formatting C-x .
--
-- CTRL-F for found concepts

-- TODO: Use insert_mode instead of both_modes where appropriate

-- TODO: Numeric arguments, stateful operations

-- TODO: Could reimplement emacs functionalities using vim.ui.input. Maybe this is a NON-GOAL

local readline_bindings = {}

function M.setup(user_config)
	local config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- TODO: Respect user configuration

	for _, mapping in ipairs(emacs_insert_bindings) do
		local modes = mapping[1]
		local keys = type(mapping[2]) == "string" and { mapping[2] } or mapping[2]
		local action = mapping[3]
		local opts = mapping[4]
		for _, k in ipairs(keys) do
			vim.keymap.set(modes, k, action, opts)
		end
	end
end

return M
