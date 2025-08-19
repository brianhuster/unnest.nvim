.PHONY: test lint lintlua linthelp format

test:
	nvim --clean -l scripts/test.lua

lintlua:
	nvim --clean -l scripts/luals.lua

linthelp:
	nvim --clean -l scripts/helptags.lua

lint: lintlua linthelp

format:
	stylua .
