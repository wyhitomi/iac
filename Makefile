.DEFAULT_GOAL := help
ENV ?= dev

.PHONY: help fmt validate test plan apply

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

fmt: ## Format Terraform and Terragrunt files
	terraform fmt -recursive
	terragrunt hclfmt

validate: ## Check formatting (CI parity)
	terraform fmt -check -recursive
	terragrunt hclfmt --terragrunt-check --terragrunt-diff

test: ## Run infra tests against the floci-gcp emulator
	./test/run.sh

plan: ## Plan an environment, e.g. `make plan ENV=prod`
	cd live/$(ENV) && terragrunt run-all plan

apply: ## Apply an environment, e.g. `make apply ENV=prod`
	cd live/$(ENV) && terragrunt run-all apply
