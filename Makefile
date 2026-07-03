.DEFAULT_GOAL := help

# Environment to act on (sandbox | test | prd) and the ref changes are diffed against.
ENV  ?= sandbox
BASE ?= origin/main
ENVIRONMENTS := sandbox test prd

.PHONY: help fmt validate test changes plan apply changes-all plan-all apply-all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

fmt: ## Format Terraform and Terragrunt files
	terraform fmt -recursive
	terragrunt hclfmt

validate: ## Check formatting (CI parity)
	terraform fmt -check -recursive
	terragrunt hclfmt --terragrunt-check --terragrunt-diff

test: ## Run infra tests against the floci-gcp emulator
	./test/run.sh

changes: ## List changed units for one env, e.g. `make changes ENV=test BASE=origin/main`
	@./scripts/changed-units.sh $(ENV) $(BASE)

plan: ## Plan only changed units for one env, e.g. `make plan ENV=prd`
	@./scripts/tg-run.sh plan $(ENV) $(BASE)

apply: ## Apply only changed units for one env, e.g. `make apply ENV=prd`
	@./scripts/tg-run.sh apply $(ENV) $(BASE)

changes-all: ## List changed units across every environment
	@for e in $(ENVIRONMENTS); do echo "== $$e =="; ./scripts/changed-units.sh $$e $(BASE) || true; done

plan-all: ## Plan changed units across every environment
	@for e in $(ENVIRONMENTS); do ./scripts/tg-run.sh plan $$e $(BASE); done

apply-all: ## Apply changed units across every environment (sandbox -> test -> prd)
	@for e in $(ENVIRONMENTS); do ./scripts/tg-run.sh apply $$e $(BASE); done
