# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION for the `external-bucket` component.
# Demonstrates sourcing a module from an EXTERNAL repository, pinned to an immutable ref.
# Terragrunt fetches, caches, and runs this exactly like a local module.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # External module: public Terraform module, pinned by tag. Prefer `git::` + `?ref=<tag>` (or a
  # commit SHA) over a mutable branch so plans are reproducible. Private repos work the same way over
  # SSH: git::ssh://git@github.com/your-org/your-modules.git//path?ref=v1.2.3
  source = "git::https://github.com/terraform-google-modules/terraform-google-cloud-storage.git//modules/simple_bucket?ref=v11.0.0"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  project_id  = local.env_vars.locals.project_id
  region      = local.env_vars.locals.region
}

inputs = {
  project_id    = local.project_id
  location      = local.region
  force_destroy = local.environment != "prd"
}
