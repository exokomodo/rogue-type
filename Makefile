SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.ONESHELL:
.SILENT:

##@ Development Environment

.PHONY: setup
setup: setup/love setup/luacheck setup/busted ## Install all development dependencies

.PHONY: setup/love
setup/love: ## Install LÖVE2D
	@if command -v love &>/dev/null; then \
		echo "love2d is already installed"; \
	elif [ "$$(uname)" = "Darwin" ]; then \
		brew install love; \
	else \
		sudo apt-get update && sudo apt-get install -y love; \
	fi

.PHONY: setup/luacheck
setup/luacheck: ## Install luacheck linter
	@if command -v luacheck &>/dev/null; then \
		echo "luacheck is already installed"; \
	else \
		sudo luarocks install luacheck; \
	fi

.PHONY: setup/busted
setup/busted: ## Install busted test framework
	@if command -v busted &>/dev/null; then \
		echo "busted is already installed"; \
	else \
		sudo luarocks install busted; \
	fi

##@ Build

.PHONY: build
build: ## Package game into build/game.love
	@mkdir -p build
	cd src && zip -9 -r ../build/game.love . && cd ..
	@if [ -d assets ] && [ "$$(ls -A assets 2>/dev/null)" ]; then \
		cd assets && zip -9 -r ../build/game.love . && cd ..; \
	fi
	echo "Built build/game.love"

.PHONY: clean
clean: ## Remove build artifacts
	@rm -rf build
	echo "Cleaned build/"

##@ Run

.PHONY: run
run: ## Run the game in development mode
	@love src/

##@ Test

.PHONY: test
test: ## Run tests with busted
	@busted tests/

##@ Code Quality

.PHONY: check
check: check/lua ## Run all code quality checks

.PHONY: check/lua
check/lua: ## Lint Lua source with luacheck
	@luacheck src/

.PHONY: format
format: ## Format Lua source with stylua (if available)
	@if command -v stylua &>/dev/null; then \
		stylua src/; \
	else \
		echo "stylua not found, skipping format"; \
	fi

##@ Helpers

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_\-\/]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

env-%: ## Check that an environment variable is set (usage: make env-VAR)
	@if [ -z "$${$*}" ]; then \
		echo "ERROR: environment variable $* is not set"; \
		exit 1; \
	fi
