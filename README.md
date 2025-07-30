# unnest.nvim

Unnest your nested Neovim sessions.

## Introduction

Imagine that you are in a terminal buffer in Nvim, and you run a command that opens a new Nvim instance (e.g., `git commit`). Now you have a Neovim session running inside another Neovim session. This can be confusing and inefficient.

`unnest.nvim` solves this by detecting when it's being run in a nested session. It then instructs the parent Neovim instance to open a new tab that replicates the window layout of the nested session. When you close the tab, the nested Nvim instance will also be closed.

## Installation

You can install `unnest.nvim` using any plugin manager that supports `git`, like [lazy.nvim](https://github.com/folke/lazy.nvim), [vim-plug](https://github.com/junegunn/vim-plug), etc. See the document of your plugin manager for how to install a plugin with them.

Nvim 0.12 has a built-in plugin manager, so you can install `unnest.nvim` using
```lua
vim.pack.add { "https://github.com/brianhuster/unnest.nvim" }
```

## Usage

This plugin works automatically. No configuration, no `setup()` is required.

NOTE: there are some other plugins that do similar thing, like [flatten.nvim](https://github.com/willothy/flatten.nvim), [nvim-unception](https://github.com/samjwill/nvim-unception). Please make sure you have removed or disabled them before installing this plugin, because they can conflict with each other.

## How It Works

1.  When a nested Neovim instance is started, the plugin connects to the parent instance via RPC.
2.  It captures the window layout of the nested instance.
3.  It sends commands to the parent instance to create a new tab with the same layout.
4.  It sets up an autocmd so that when the new tab is closed, the parent Neovim instance is notified, and the nested instance is closed.
