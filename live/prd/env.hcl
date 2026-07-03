# Environment-level variables for `prd`. Read by root.hcl and the _envcommon includes.
locals {
  environment = "prd"
  project_id  = "my-org-prd"
  region      = "us-central1"
}
