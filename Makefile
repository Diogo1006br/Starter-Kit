# Docker is the only requirement: PHP, Composer and Node run in containers.
# Run `make help` for the list of commands.

COMPOSE ?= docker compose
RUN_BACKEND  = $(COMPOSE) run --rm --no-deps backend
RUN_FRONTEND = $(COMPOSE) run --rm --no-deps frontend
# Arguments for the pass-through targets: make artisan c="migrate:status"
c ?=

.DEFAULT_GOAL := help
.PHONY: help init env check-docker build up up-workers down stop restart ps logs health \
        shell-backend shell-frontend artisan composer npm migrate fresh \
        test test-pg lint format format-check build-frontend check versions reset

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

check-docker:
	@docker info >/dev/null 2>&1 || { echo "Docker is not running. Start Docker and retry."; exit 1; }

env: ## Create .env (if missing) and generate local secrets
	@./bin/setup-env

init: check-docker env ## One-shot setup: images, dependencies, APP_KEY, services, migrations
	$(COMPOSE) build
	@echo "==> Installing PHP dependencies (composer.lock)"
	$(RUN_BACKEND) composer install --no-interaction --prefer-dist
	@echo "==> Installing JS dependencies (package-lock.json)"
	$(RUN_FRONTEND) sh -c 'if [ -f package-lock.json ]; then npm ci; else npm install; fi'
	@if ! grep -qE '^APP_KEY=.+' .env; then \
	  echo "==> Generating APP_KEY"; \
	  key=$$($(RUN_BACKEND) php artisan key:generate --show --no-ansi | tr -d '\r\n'); \
	  awk -v v="$$key" 'BEGIN{FS=OFS="="} $$1=="APP_KEY" {print "APP_KEY=" v; next} {print}' .env > .env.tmp && cat .env.tmp > .env && rm -f .env.tmp; \
	fi
	@echo "==> Starting services"
	$(COMPOSE) up -d --wait
	@echo "==> Running migrations"
	$(COMPOSE) exec backend php artisan migrate --force
	@echo ""
	@echo "Ready:  frontend http://localhost:$$(grep -E '^FRONTEND_PORT=' .env | cut -d= -f2)   api http://localhost:$$(grep -E '^BACKEND_PORT=' .env | cut -d= -f2)/api/v1/health"

build: check-docker ## Build the Docker images
	$(COMPOSE) build

up: check-docker ## Start all services
	$(COMPOSE) up -d --wait

up-workers: check-docker ## Start services plus queue worker and scheduler
	$(COMPOSE) --profile workers up -d --wait

down: ## Stop and remove containers (data volumes are kept)
	$(COMPOSE) --profile workers down

stop: ## Stop containers without removing them
	$(COMPOSE) --profile workers stop

restart: down up ## Restart all services

ps: ## Show service status and health
	$(COMPOSE) ps

logs: ## Follow logs (optionally: make logs c=backend)
	$(COMPOSE) logs -f --tail=100 $(c)

health: ## Call the API health endpoint (database + redis)
	@curl -fsS http://localhost:$$(grep -E '^BACKEND_PORT=' .env | cut -d= -f2)/api/v1/health; echo

shell-backend: ## Shell inside the backend container
	$(COMPOSE) exec backend bash

shell-frontend: ## Shell inside the frontend container
	$(COMPOSE) exec frontend sh

artisan: ## Run artisan: make artisan c="migrate:status"
	$(COMPOSE) exec backend php artisan $(c)

composer: ## Run composer: make composer c="require vendor/package"
	$(RUN_BACKEND) composer $(c)

npm: ## Run npm in the frontend: make npm c="install some-package"
	$(RUN_FRONTEND) npm $(c)

migrate: ## Run database migrations
	$(COMPOSE) exec backend php artisan migrate --force

fresh: ## Drop all tables, re-run migrations (development data is lost)
	$(COMPOSE) exec backend php artisan migrate:fresh --force

test: ## Backend (SQLite in memory) and frontend tests
	$(RUN_BACKEND) composer test
	$(RUN_FRONTEND) npm test

test-pg: ## Backend tests against real PostgreSQL (<DB_DATABASE>_test)
	$(COMPOSE) run --rm -e DB_DATABASE=$$(grep -E '^DB_DATABASE=' .env | cut -d= -f2)_test backend composer test:pgsql

lint: ## Pint (backend) + Oxlint (frontend)
	$(RUN_BACKEND) composer lint
	$(RUN_FRONTEND) npm run lint

format: ## Apply Pint (backend) + Prettier (frontend)
	$(RUN_BACKEND) composer format
	$(RUN_FRONTEND) npm run format

format-check: ## Check Prettier formatting (frontend)
	$(RUN_FRONTEND) npm run format:check

build-frontend: ## Type-check and build the frontend
	$(RUN_FRONTEND) npm run build

check: lint format-check test test-pg build-frontend ## Everything CI runs

versions: ## Print versions actually installed inside the containers
	@$(RUN_BACKEND) sh -c 'php -v | head -1; composer --version; php artisan --version; php -r "echo \"phpredis \".phpversion(\"redis\").PHP_EOL;"; composer show --direct --no-ansi'
	@$(RUN_FRONTEND) sh -c 'echo "node $$(node -v)  npm $$(npm -v)"; npm ls --depth=0 --no-progress'

reset: ## DANGER: remove containers AND data volumes (database, redis)
	$(COMPOSE) --profile workers down -v
