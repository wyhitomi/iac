# Environment-level variables for `prod`. Read by root.hcl and the _envcommon includes.
locals {
  environment = "prod"
  project_id  = "my-org-prod"
  region      = "us-central1"
}
