# ---------------------------------------------------------------------------------------------------------------------
# ROOT TERRAGRUNT CONFIGURATION — local cloud target.
# Included by every unit under env/local/**. Points the google provider at a locally running
# floci-gcp emulator instead of real GCP, and keeps state on disk — there is no real cloud
# project backing this environment, so it needs no credentials and costs nothing to iterate on.
#
# Start the emulator first:  docker compose -f test/docker-compose.yml up -d
# ---------------------------------------------------------------------------------------------------------------------

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  project_id     = local.env_vars.locals.project_id
  region         = local.env_vars.locals.region
  floci_endpoint = local.env_vars.locals.floci_endpoint
}

# ---------------------------------------------------------------------------------------------------------------------
# STATE
# Plain local state file per unit — nothing durable to protect, no bucket to provision.
# ---------------------------------------------------------------------------------------------------------------------
remote_state {
  backend = "local"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER
# Fake token + custom endpoints so the provider never reaches for real ADC or real GCP.
# Add more `*_custom_endpoint` overrides here as more services are exercised locally.
# ---------------------------------------------------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  project      = "${local.project_id}"
  region       = "${local.region}"
  access_token = "floci-fake-token"

  storage_custom_endpoint = "${local.floci_endpoint}/storage/v1/"
}
EOF
}

inputs = merge(
  local.env_vars.locals,
  {}
)
