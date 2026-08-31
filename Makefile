# NeuViTech Labs — the single command interface.
#
# One command set regardless of operating system or shell, because every
# target runs inside the Dev Container. If you are typing an OS-specific
# command, something has gone wrong — tell the team.
#
# Targets marked [Sprint N] arrive with that sprint. They print a pointer
# rather than "command not found", so `make help` always shows the full
# command surface.

.DEFAULT_GOAL := help
SHELL := /bin/bash
API := apps/api
WEB := apps/web

.PHONY: help up down logs ps api web worker shell migrate migration seed \
        reset-db test test-api test-web e2e load lint fmt typecheck check \
        guardrails contracts scan clean doctor

## ---------------------------------------------------------------- meta

help:  ## Show this help
	@echo ""
	@echo "  NeuViTech Labs"
	@echo "  ─────────────────────────────────────────────────────────"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo ""

doctor:  ## Verify the toolchain — run on Day 6 and any time something feels wrong
	@echo ""
	@echo "Toolchain:"
	@bash scripts/doctor.sh
	@echo ""
	@echo "Compare this output with the other machine. It must match exactly."
	@echo "Any difference is a bug in .devcontainer/, fixed there — never locally."

## ---------------------------------------------------------------- services

up:       ## Start all services                          [Sprint 2 — NVL-202]
	@$(call pending,NVL-202,infrastructure/compose/docker-compose.yml)
down:     ## Stop all services                           [Sprint 2 — NVL-202]
	@$(call pending,NVL-202,infrastructure/compose/docker-compose.yml)
logs:     ## Tail all service logs                       [Sprint 2 — NVL-202]
	@$(call pending,NVL-202,infrastructure/compose/docker-compose.yml)
ps:       ## Show what is running                        [Sprint 2 — NVL-202]
	@$(call pending,NVL-202,infrastructure/compose/docker-compose.yml)

## ---------------------------------------------------------------- run

api:      ## Run the API with reload                     [Sprint 2 — NVL-201]
	@$(call pending,NVL-201,apps/api)
web:      ## Run the web app                             [Sprint 2 — NVL-209]
	@$(call pending,NVL-209,apps/web)
worker:   ## Run the ARQ worker                          [Sprint 4]
	@$(call pending,NVL-E05,apps/api/src/neuvitech/workers)
shell:    ## Python REPL with app context                [Sprint 2 — NVL-201]
	@$(call pending,NVL-201,apps/api)

## ---------------------------------------------------------------- data

migrate:   ## Apply migrations                           [Sprint 2 — NVL-205]
	@$(call pending,NVL-205,apps/api/migrations)
migration: ## Create a migration: make migration m="..."  [Sprint 2 — NVL-205]
	@$(call pending,NVL-205,apps/api/migrations)
seed:      ## Seed development data                      [Sprint 2 — NVL-206]
	@$(call pending,NVL-206,scripts/seed.py)
reset-db:  ## Drop, recreate, migrate, seed              [Sprint 2 — NVL-205]
	@$(call pending,NVL-205,apps/api/migrations)

## ---------------------------------------------------------------- quality

lint:      ## Ruff + ESLint                              [Sprint 2 — NVL-210]
	@$(call pending,NVL-210,apps/api)
fmt:       ## Auto-format everything                     [Sprint 2 — NVL-210]
	@$(call pending,NVL-210,apps/api)
typecheck: ## mypy + tsc                                 [Sprint 2 — NVL-210]
	@$(call pending,NVL-210,apps/api)
test:      ## Run all tests                              [Sprint 2 — NVL-210]
	@$(call pending,NVL-210,apps/api/tests)
test-api:  ## Backend tests only                         [Sprint 2 — NVL-210]
	@$(call pending,NVL-210,apps/api/tests)
test-web:  ## Frontend tests only                        [Sprint 3]
	@$(call pending,NVL-E03,apps/web/tests)
e2e:       ## Playwright end-to-end                      [Sprint 3]
	@$(call pending,NVL-E03,apps/web/tests/e2e)
load:      ## k6 load tests                              [Sprint 13]
	@$(call pending,NVL-E16,infrastructure/k6)

guardrails:  ## Check the architectural rules (docs/05, 06, 08, 11)
	@if [ -f scripts/check_guardrails.py ]; then \
	  python scripts/check_guardrails.py apps/ ; \
	else \
	  echo "scripts/check_guardrails.py not present yet — copy it from the skill package."; \
	fi

check:     ## lint + typecheck + guardrails + test — run before every push
	@echo "Sprint 1: nothing to check yet. Chain becomes real in Sprint 2 (NVL-210)."
	@$(MAKE) --no-print-directory guardrails

contracts: ## Regenerate TypeScript from OpenAPI          [Sprint 2 — NVL-209]
	@$(call pending,NVL-209,packages/contracts)
scan:      ## Security scans                             [Sprint 3 — NVL-309]
	@$(call pending,NVL-309,.github/workflows)

## ---------------------------------------------------------------- housekeeping

clean:  ## Remove caches and build artefacts
	@find . -type d -name __pycache__   -prune -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name .pytest_cache -prune -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name .ruff_cache   -prune -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name .mypy_cache   -prune -exec rm -rf {} + 2>/dev/null || true
	@rm -rf $(WEB)/.next $(WEB)/.turbo 2>/dev/null || true
	@echo "Cleaned."

define pending
	echo ""; \
	echo "  Not implemented yet — arrives with $(1)."; \
	echo "  Expected location: $(2)"; \
	echo "  See docs/25-master-roadmap.md and docs/27-jira-backlog.md."; \
	echo ""
endef
