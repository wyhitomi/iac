# Environment-level variables for `test`. Read by root.hcl and the _envcommon includes.
locals {
  environment = "test"
  project_id  = "my-org-test"
  region      = "us-central1"
}
