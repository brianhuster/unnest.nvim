PYTHON ?= python3

.PHONY: test lint lintlua linthelp format

ifeq ($(OS),Windows_NT)
  PIP := .venv/Scripts/pip.exe
  PYTEST := .venv/Scripts/pytest.exe
else
  PIP := .venv/bin/pip
  PYTEST := .venv/bin/pytest
endif

.venv/touchfile: test/requirements.txt
	$(PYTHON) -m venv .venv
	$(PIP) install -r test/requirements.txt
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
