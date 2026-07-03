# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION for the `network` component.
# Sourced from a LOCAL module in this repo.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/network"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  project_id  = local.env_vars.locals.project_id
  region      = local.env_vars.locals.region
}

inputs = {
  project_id   = local.project_id
  region       = local.region
  network_name = "${local.environment}-vpc"
  subnets = [
    {
      name          = "${local.environment}-primary"
      ip_cidr_range = "10.10.0.0/20"
    },
  ]
}
