# Native `terraform test` suite. Each run block applies the fixture against the running
# floci-gcp emulator and asserts on real provider outputs, then Terraform destroys it.

run "creates_bucket" {
  command = apply

  assert {
    condition     = module.bucket.name == "floci-test-bucket"
    error_message = "Bucket name output did not match the requested name."
  }

  assert {
    condition     = module.bucket.url == "gs://floci-test-bucket"
    error_message = "Bucket URL output was not the expected gs:// URL."
  }
}
