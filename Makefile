.PHONY: server setup test

export MIX_ENV ?= dev
export SECRET_KEY_BASE ?= $(shell mix phx.gen.secret)

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`

default: help

#check: @ 🔍 Runs all the main CI targets
check: security.ci lint.ci test.cover dialyzer

#clean: @ 🧹 Cleans all dependencies
clean: clean.npm clean.deps

#clean.deps: @ 🧹 Cleans server dependencies from mix.exs
clean.deps:
	@echo "📦 Fetching any missing Elixir dependency before re-installing..."
	@mix deps.get
	@echo "🧹 Starting Elixir dependencies clean up..."
	@mix deps.clean --all
	@mix deps.get

#clean.npm: @ 🧹 Cleans client dependencies from assets/package.json
clean.npm:
	@npm clean-install --prefix assets

#dialyzer: @ 🔍 Performs static code analysis.
dialyzer:
	@mix dialyzer --format dialyxir

#docker.services.down: @ 🐳 Shuts down docker-compose services
docker.services.down:
	@docker-compose down

#docker.services.up: @ 🐳 Starts docker-compose services
docker.services.up: SHELL:=/bin/bash
docker.services.up:
	source .env && docker-compose up -d

#ecto.reset: @ 🧹 Drops the database, then runs setup
ecto.reset: SHELL:=/bin/bash
ecto.reset: docker.services.up
ecto.reset:
	source .env && POOL_SIZE=2 mix ecto.reset

#help: @ ❓ Displays this message
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

#install: @ 📦 Installs all dependencies
install: install.deps install.npm

#install.deps: @ 📦 Installs server dependencies from mix.exs
install.deps:
	@mix deps.get

#install.npm: @ 📦 Installs client dependencies from assets/package.json
install.npm:
	@npm i --prefix assets

#lint: @ 🔍 Runs a code formatter, a code consistency analysis and eslint for js modules
lint:
	@mix format
	@mix credo --strict
	@mix eslint.fix

#lint.ci: @ 🔍 Strictly runs a code formatter, a code consistency analysis and eslint for js modules
lint.ci:
	@mix format --check-formatted
	@mix credo --strict
	@mix eslint

#reset: @ 💣 Shuts down docker services and cleans all dependencies, then resets the database and re-installs all dependencies
reset: docker.services.down
reset: docker.services.up
reset: clean.npm
reset: ecto.reset

#security.check: @ 🛡️  Performs security checks
security.check:
	@mix sobelow --verbose

#security.ci: @ 🛡️  Performs security checks. Exits on error.
security.ci:
	@mix sobelow --exit

#server: @ ‍💻 Starts a server with an interactive elixir shell.
server: SHELL:=/bin/bash
server: docker.services.up
server:
	source .env && iex --name $(APP_NAME)@127.0.0.1 -S mix phx.server

#setup: @ 📦 Installs all dependencies, recreates the database, runs migrations and loads database seeds up.
setup: SHELL:=/bin/bash
setup: docker.services.up
setup:
	source .env && POOL_SIZE=2 mix setup

#test: @ 🧪 Runs all test suites
test: MIX_ENV=test
test: SHELL:=/bin/bash
test:
	@echo "🧪 Running all test suites..."
	source .env && mix test

#test.watch: @ 🧪👁️ Runs and watches all test suites
test.watch: SHELL:=/bin/bash
test.watch:
	@echo "🧪👁️  Watching all test suites..."
	source .env && mix test.watch

#test.cover: @ 📉 Runs mix tests and generates coverage
test.cover: MIX_ENV=test
test.cover: SHELL:=/bin/bash
test.cover:
	source .env && mix coveralls.html

#test.drop: @ 🧹 Drops the test database. Usually used after schemas change.
test.drop: MIX_ENV=test
test.drop: SHELL:=/bin/bash
test.drop:
	source .env && mix ecto.drop

#test.wip: @ 🧪 Runs test suites that match the wip tag
test.wip: MIX_ENV=test
test.wip: SHELL:=/bin/bash
test.wip:
	source .env && mix test --only wip

#test.wip.watch: @ 🧪👁️ Runs and watches test suites that match the wip tag
test.wip.watch: SHELL:=/bin/bash
test.wip.watch:
	@echo "🧪👁️  Watching test suites tagged with wip..."
	source .env && mix test.watch --only wip
