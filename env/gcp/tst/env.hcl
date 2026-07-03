# Environment-level variables for `gcp/tst`. Read by root.hcl and the _envcommon includes.
locals {
  environment = "tst"
  project_id  = "my-org-tst"
  region      = "us-central1"
}
