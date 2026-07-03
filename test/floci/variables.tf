variable "project_id" {
  type    = string
  default = "floci-test"
}

variable "region" {
  type    = string
  default = "us-central1"
}

# Base URL of the floci-gcp Cloud Storage API. Overridable so the same fixture can
# run against a different emulator host/port in CI.
variable "storage_endpoint" {
  type    = string
  default = "http://localhost:4588/storage/v1/"
}
