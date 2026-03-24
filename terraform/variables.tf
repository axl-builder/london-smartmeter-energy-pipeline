variable "project" {
  description = "Tu ID de Proyecto de GCP"
  default     = "smart-meters-london"
}

variable "region" {
  description = "Región de los recursos"
  default     = "us-central1"
}

variable "location" {
  description = "Ubicación del bucket/dataset"
  default     = "US"
}

variable "gcs_bucket_name" {
  description = "Nombre base para el bucket"
  default     = "london_energy_datalake"
}