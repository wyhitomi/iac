# Environment-level variables for the `local` target. Read by root.hcl and the _envcommon includes.
# Not a real GCP project — floci_endpoint points the google provider at the floci-gcp emulator.
locals {
  environment    = "local"
  project_id     = "iac-local"
  region         = "us-central1"
  floci_endpoint = "http://localhost:4588"
}
