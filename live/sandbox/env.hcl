# Environment-level variables for `sandbox`. Read by root.hcl and the _envcommon includes.
locals {
  environment = "sandbox"
  project_id  = "my-org-sandbox"
  region      = "us-central1"
}
