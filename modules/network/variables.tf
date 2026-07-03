variable "project_id" {
  description = "GCP project that owns the network."
  type        = string
}

variable "region" {
  description = "Region for the subnetwork."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "subnets" {
  description = "Subnetworks to create within the VPC."
  type = list(object({
    name          = string
    ip_cidr_range = string
  }))
  default = []
}
