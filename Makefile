PYTHON ?= python3

.PHONY: help test lint format

ifeq ($(OS),Windows_NT)
  PIP := .venv/Scripts/pip.exe
  PYTEST := .venv/Scripts/pytest.exe
else
  PIP := .venv/bin/pip
  PYTEST := .venv/bin/pytest
endif

help:
	@echo "Commands:"
	@echo "test     - Run all tests within the virtual environment"
	@echo "          You can override the Python interpreter by setting the PYTHON variable,"
	@echo "          e.g., 'make test PYTHON=python'"
	@echo "lint     - Lint with lua-language-server"
	@echo "format   - Format code with stylua"

.venv/touchfile: test/requirements.txt
	$(PYTHON) -m venv .venv
	$(PIP) install -r test/requirements.txt
	touch .venv/touchfile

test: .venv/touchfile
	$(PYTEST) test

lint:
	VIMRUNTIME=$$(nvim --clean --headless +"lua io.stdout:write(vim.env.VIMRUNTIME)" +q) \
	lua-language-server --check=. --configpath=.nvim.lua

format:
	stylua .
