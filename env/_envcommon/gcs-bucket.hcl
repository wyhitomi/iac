# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION for the `gcs-bucket` component.
# Sourced from a LOCAL module in this repo. Environments include this file and override inputs as needed.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # Local module: relative to the repo root. `get_repo_root()` keeps this stable regardless of unit depth.
  source = "${get_repo_root()}/modules/gcs-bucket"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  project_id  = local.env_vars.locals.project_id
}

inputs = {
  project_id    = local.project_id
  location      = local.env_vars.locals.region
  force_destroy = local.environment != "prd"
  versioning    = true
  labels = {
    environment = local.environment
    managed_by  = "terragrunt"
  }
}
