# Environment-level variables for `dev`. Read by root.hcl and the _envcommon includes.
locals {
  environment = "dev"
  project_id  = "my-org-dev"
  region      = "us-central1"
}
