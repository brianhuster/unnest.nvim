PYTHON ?= python3

.PHONY: help test

ifeq ($(OS),Windows_NT)
  PIP := .venv/Scripts/pip.exe
  PYTEST := .venv/Scripts/pytest.exe
else
  PIP := .venv/bin/pip
  PYTEST := .venv/bin/pytest
endif

help:
	@echo "Commands:"
	@echo "test    - Run all tests within the virtual environment"
	@echo ""
	@echo "You can override the Python interpreter by setting the PYTHON variable,"
	@echo "e.g., 'make test PYTHON=python'"

.venv/touchfile: test/requirements.txt
	$(PYTHON) -m venv .venv
	$(PIP) install -r test/requirements.txt
	touch .venv/touchfile

test: .venv/touchfile
	$(PYTEST) test
