# Contributing to unnest.nvim

## Reporting issues

If you have a problem with unnest.nvim, please [open an
issue](https://github.com/brianhuster/unnest.nvim/issues/new) and do as instructed

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

To test locally, run `make test`.

### Commit messages

This project uses [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/). Please follow the
guidelines.
