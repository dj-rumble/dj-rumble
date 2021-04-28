.PHONY: server setup test

export MIX_ENV ?= dev
export SECRET_KEY_BASE ?= $(shell mix phx.gen.secret)

# Enables bash commands in the whole document
# SHELL := /bin/bash

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`

default: help

#clean: @ Cleans all dependencies
clean: clean.npm clean.deps

#clean.deps: @ Cleans server dependencies from mix.exs
clean.deps:
	@mix deps.clean --all

#clean.npm: @ Cleans client dependencies from assets/package.json
clean.npm:
	@npm clean-install --prefix assets

#docker.services.down: @ Shuts down docker-compose services
docker.services.down:
	@docker-compose down

#docker.services.up: @ Starts docker-compose services
docker.services.up: SHELL:=/bin/bash
docker.services.up: 
	source .env && docker-compose up -d

#ecto.reset: @ Drops the database, then runs setup
ecto.reset: SHELL:=/bin/bash
ecto.reset: docker.services.up
ecto.reset: 
	source .env && POOL_SIZE=2 mix ecto.reset

#help: @ Displays this message
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

#install: @ Installs all dependencies
install: install.deps install.npm

#install.deps: @ Installs server dependencies from mix.exs
install.deps:
	@mix deps.get

#install.npm: @ Installs client dependencies from assets/package.json
install.npm:
	@npm i --prefix assets

#lint: @ Runs a code formatter, analyzes code consistency, performs security checks and static code analysis.
lint:
	@mix quality

#lint: @ Runs a static code analysis and strictly checks code format, code style and security checks.
lint.ci:
	@mix quality.ci

#reset: @ Shuts down docker services and cleans all dependencies, then runs setup
reset: docker.services.down
reset: clean
reset: setup

#server: @ Starts a server with an interactive elixir shell.
server: SHELL:=/bin/bash
server: docker.services.up
server:
	source .env && iex --name $(APP_NAME)@127.0.0.1 -S mix phx.server

#setup: @ Installs all dependencies, recreates the database, runs migrations and loads database seeds up.
setup: SHELL:=/bin/bash
setup: docker.services.up
setup:
	source .env && POOL_SIZE=2 mix setup

#test: @ Runs all test suites
test: MIX_ENV=test
test: SHELL:=/bin/bash
test:
	source .env && mix test

#test.cover: @ Runs mix tests and generates coverage
test.cover: MIX_ENV=test
test.cover: SHELL:=/bin/bash
test.cover:
	source .env && mix coveralls.html

#test.drop: @ Drops the test database. Usually used after schemas change.
test.drop: MIX_ENV=test
test.drop: SHELL:=/bin/bash
test.drop:
	source .env && DB_DATABASE=dj_rumble_test && mix ecto.drop

#test.wip: @ Runs test suites that match the wip tag
test.wip: MIX_ENV=test
test.wip: SHELL:=/bin/bash
test.wip:
	source .env && mix test --only wip
