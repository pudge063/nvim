NVIM ?= nvim

ROOT       := $(CURDIR)
TEST_HOME  := $(ROOT)/.test-home
FIXTURES   := $(ROOT)/tests/fixtures/python_project

export XDG_CONFIG_HOME := $(TEST_HOME)/config
export XDG_DATA_HOME   := $(TEST_HOME)/data
export XDG_STATE_HOME  := $(TEST_HOME)/state
export XDG_CACHE_HOME  := $(TEST_HOME)/cache

INIT := $(XDG_CONFIG_HOME)/nvim/init.lua

.PHONY: setup test test-only clean help

help:
	@echo "make setup      - point an isolated nvim config at this repo, sync plugins, install mason tools, prep fixtures"
	@echo "make test       - setup (if needed) + run the full test suite"
	@echo "make test-only  - run the test suite without re-running setup (fast, assumes setup already ran)"
	@echo "make clean      - remove the isolated test environment and generated fixture state"

setup:
	mkdir -p "$(XDG_CONFIG_HOME)"
	ln -sfn "$(ROOT)" "$(XDG_CONFIG_HOME)/nvim"
	@echo "--- syncing plugins ---"
	"$(NVIM)" --headless -u "$(INIT)" -c "lua require('lazy').sync({ wait = true, show = false })" -c "qa"
	@echo "--- installing LSP/formatter tools via mason ---"
	"$(NVIM)" --headless -u "$(INIT)" "+MasonToolsInstallSync" +qa
	@echo "--- preparing fixtures ---"
	mkdir -p "$(FIXTURES)/.venv/bin"
	printf '#!/bin/sh\nexec python3 "$$@"\n' > "$(FIXTURES)/.venv/bin/python"
	chmod +x "$(FIXTURES)/.venv/bin/python"
	@if [ ! -d "$(FIXTURES)/.git" ]; then \
		git -C "$(FIXTURES)" init -q -b main; \
		git -C "$(FIXTURES)" -c user.email=test@test -c user.name=test add -A; \
		git -C "$(FIXTURES)" -c user.email=test@test -c user.name=test commit -q -m "fixture"; \
	fi

test: setup
	@$(MAKE) test-only

test-only:
	@# plenary.nvim is only ever pulled in as a lazy dependency of
	@# telescope/neo-tree in this config, so it isn't on the runtimepath
	@# (and :PlenaryBustedDirectory isn't defined) until forced.
	"$(NVIM)" --headless -u "$(INIT)" \
		-c "lua require('lazy').load({ plugins = { 'plenary.nvim' } })" \
		-c "PlenaryBustedDirectory tests/config { init = '$(INIT)', sequential = true, timeout = 30000 }"

clean:
	rm -rf "$(TEST_HOME)"
	rm -rf "$(FIXTURES)/.venv" "$(FIXTURES)/.git"
