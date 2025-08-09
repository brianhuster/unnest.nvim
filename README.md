# unnest.nvim

Unnest your nested Neovim sessions.

## Introduction

Imagine that you are in a terminal buffer in Nvim, and you run a command that
opens a new Nvim instance (e.g., `git commit`). Now you have a Neovim session
running inside another Neovim session. This can be confusing and inefficient.

`unnest.nvim` solves this by detecting when it's being run in a nested
session, then it will instruct the parent Neovim instance to open files in a
in the parent Neovim instance.

## Features

- Minimal : < 150 LOC
- Simple to install and use : no configuration, no `setup()` is required.
- Powerful
    - You use commands like `git commit`, `git rebase -i`, `git mergetool` in Nvim without any other plugins (as long as you set `git mergetool` to use Nvim)
    - `:UnnestEdit` allows you to integrate file explorers like [FZF](https://github.com/junegunn/fzf), [Yazi](https://github.com/sxyazi/yazi), etc with Nvim

## Demo

**Using unnest.nvim with `git commit` and `git mergetool`**

https://github.com/user-attachments/assets/873a02d0-e2f6-4200-af8b-b46f4525107a

## Installation

Requires Nvim 0.11 or later.

You can install `unnest.nvim` using any plugin manager that supports `git`, like [lazy.nvim](https://github.com/folke/lazy.nvim), [vim-plug](https://github.com/junegunn/vim-plug), etc. See the documentation of your plugin manager for how to install a plugin with them.

Nvim 0.12 has a built-in plugin manager, so you can also install `unnest.nvim` using
```lua
vim.pack.add { "https://github.com/brianhuster/unnest.nvim" }
```

> [!WARNING]
> There are some other plugins that do similar thing, like [flatten.nvim](https://github.com/willothy/flatten.nvim), [nvim-unception](https://github.com/samjwill/nvim-unception). Please make sure you have removed or disabled them before installing this plugin, because they can conflict with each other.

> [!WARNING]
> This plugin doesn't support lazy-loading (and you shouldn't need it because this plugin already has very small startuptime)

## Usage

See [`:h unnest`](./doc/unnest.txt) for more details.

## Buy me a coffee

If you find this project helpful, please consider supporting me :>

<a href="https://paypal.me/brianphambinhan">
    <img src="https://www.paypalobjects.com/webstatic/mktg/logo/pp_cc_mark_111x69.jpg" alt="Paypal" style="height: 69px;">
</a>
<a href="https://img.vietqr.io/image/mb-9704229209586831984-print.png?addInfo=Donate%20for%20unnest%20nvim%20plugin&accountName=PHAM%20BINH%20AN">
    <img src="https://github.com/user-attachments/assets/f28049dc-ce7c-4975-a85e-be36612fd061" alt="VietQR" style="height: 85px;">
</a>
