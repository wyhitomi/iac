terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }
}

# Point the google provider at the floci-gcp emulator. A static fake token keeps the
# provider from reaching out for Application Default Credentials; floci ignores auth.
provider "google" {
  project      = var.project_id
  region       = var.region
  access_token = "floci-fake-token"

  storage_custom_endpoint = var.storage_endpoint
}

module "bucket" {
  source = "../../modules/gcs-bucket"

  name       = "floci-test-bucket"
  project_id = var.project_id
  location   = "US"
  # The emulator has nothing durable to protect; allow clean teardown between runs.
  force_destroy = true
}
