variable "name" {
  description = "Name of the GCS bucket (must be globally unique)."
  type        = string
}

variable "project_id" {
  description = "GCP project that owns the bucket."
  type        = string
}

variable "location" {
  description = "Location/region for the bucket."
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class for the bucket."
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it still contains objects."
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Enable object versioning."
  type        = bool
  default     = true
}

variable "uniform_bucket_level_access" {
  description = "Enforce uniform bucket-level access (disables ACLs)."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to the bucket."
  type        = map(string)
  default     = {}
}
