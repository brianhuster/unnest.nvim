.PHONY: test lint lintlua linthelp format

ifeq ($(OS),Windows_NT)
  PYTEST := .venv/Scripts/pytest.exe
else
  PYTEST := .venv/bin/pytest
endif

.venv/touchfile: uv.lock
	uv sync
	touch .venv/touchfile

test: .venv/touchfile
	$(PYTEST) test

lintlua:
	nvim --clean -l scripts/luals.lua

linthelp:
	nvim --clean -l scripts/helptags.lua

lint: lintlua linthelp

format:
	stylua .
