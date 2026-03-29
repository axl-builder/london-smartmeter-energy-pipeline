variable "project" {
  description = "Your GCP Project ID"
  default     = "smart-meters-london"
}

variable "region" {
  description = "Resource region"
  default     = "us-central1"
}

variable "location" {
  description = "Bucket/dataset location"
  default     = "US"
}

variable "gcs_bucket_name" {
  description = "Base name for the bucket"
  default     = "london_energy_datalake"
}