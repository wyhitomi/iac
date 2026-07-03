# ---------------------------------------------------------------------------------------------------------------------
# ROOT TERRAGRUNT CONFIGURATION
# This file is included by every child terragrunt.hcl via `find_in_parent_folders("root.hcl")`.
# It wires up remote state, the provider, and common inputs so individual units stay DRY.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Load environment-level variables (project_id, region, environment name).
  # Each `live/<env>` directory ships an env.hcl consumed here.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  project_id  = local.env_vars.locals.project_id
  region      = local.env_vars.locals.region
  environment = local.env_vars.locals.environment

  # Bucket that holds Terraform state, one per project. Created out-of-band (see README).
  state_bucket = "${local.project_id}-tfstate"
}

# ---------------------------------------------------------------------------------------------------------------------
# REMOTE STATE
# GCS backend with a per-unit key derived from the path relative to this repo root.
# ---------------------------------------------------------------------------------------------------------------------
remote_state {
  backend = "gcs"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    project  = local.project_id
    location = local.region
    bucket   = local.state_bucket
    prefix   = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER
# Generated so every unit gets an identically-configured google provider.
# ---------------------------------------------------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
}

provider "google-beta" {
  project = "${local.project_id}"
  region  = "${local.region}"
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# COMMON INPUTS
# Merged into the inputs of every unit that includes this file.
# ---------------------------------------------------------------------------------------------------------------------
inputs = merge(
  local.env_vars.locals,
  {}
)
