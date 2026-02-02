# Contributing to unnest.nvim

## Reporting issues

If you have a problem with unnest.nvim, please [open an
issue](https://github.com/brianhuster/unnest.nvim/issues/new) and do as
instructed

## Pull requests

If you would like to contribute to unnest.nvim, please [open a pull
request](https://github.com/brianhuster/unnest.nvim/pulls).

Bug fixes are always welcome, but new features should be discussed in an issue
before being implemented.

When working with this plugin's codebase, it is recommended to have the
following tools installed:
- [editorconfig](https://editorconfig.org) plugin (which should be [available
  and enabled by default in
  Neovim](https://neovim.io/doc/user/editorconfig.html#_editorconfig-integration))
- [lua-language-server](https://github.com/sumneko/lua-language-server) (for
  linting)
- [stylua](https://github.com/JohnnyMorganz/StyLua) (for formatting)

### Linting

You need `lua-language-server` installed to lint the code. You can lint locally
by running `make lint`.

### Formatting

You need `stylua` installed to format the code. You can format locally by
running `make format`.

### Testing

Tests are written in Python using
[pytest](https://github.com/pytest-dev/pytest) and
[pynvim](https://github.com/neovim/pynvim).

To test locally, first you need to install
[uv](https://github.com/astral-sh/uv). Then you can just run `make test`.
You can make test use your Python executable of choice with `make test
PYTHON=path/to/python`.

For how to control a Nvim instance in test with pynvim, see [if_pyth
documentation](https://neovim.io/doc/user/if_pyth.html) and [pynvim
documentation](https://pynvim.readthedocs.io/en/latest/).

### Commit messages

This project uses [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/). Please follow the
guidelines.
