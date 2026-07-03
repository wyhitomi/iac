# gcs-bucket

A thin, opinionated wrapper around `google_storage_bucket` with sane, secure defaults
(uniform bucket-level access and versioning enabled by default).

This is a **local module** — consumed from `env/**` via a `${get_repo_root()}/modules/gcs-bucket`
source (see `env/_envcommon/gcs-bucket.hcl`). See the repo README for how to consume modules
from external repos instead.

## Usage

```hcl
terraform {
  source = "${get_repo_root()}/modules/gcs-bucket"
}

inputs = {
  name       = "my-app-assets"
  project_id = "my-project"
  location   = "US"
}
```

<!-- BEGIN_TF_DOCS -->
<!-- Run `terraform-docs .` to populate this section. -->
<!-- END_TF_DOCS -->
