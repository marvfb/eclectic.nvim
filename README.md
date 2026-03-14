# eclectic.nvim

Emacs insert mode bindings for neovim.

## Demo

## Installation

## Configuration


## Scope and Vision

The primary goal of this plugin is to make emacs-style insert bindings
available to neovim users. Compared to similar plugin, this plugin tries
to implement as much as possible. Most emacs commands may be expressed
as a simple neovim command, while others need to be reimplemented in
lua.

### Missing Features

Some functions are still unimplemented, here is a list.

TODO

To achieve parity, we also might have to reimplement some commands
that are currently expressed as a neovim command as a custom lua
function. I am not obsessed with parity, but if you are, feel free to
submit a pull request.

### Explicit Non-Goals

This plugin will not port emacs lisp or maintain neovim documentation
in emacs' style. The scope should remain limited.
