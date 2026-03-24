terraform {
  required_version = ">= 1.0"
  backend "local" {} # Podés cambiarlo a "gcs" más adelante si querés guardar el estado en la nube
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# 1. DATA LAKE: Google Cloud Storage Bucket
resource "google_storage_bucket" "data_lake_bucket" {
  name          = "${var.gcs_bucket_name}_${var.project}" # Nombre único
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 30 # Autolimpieza a los 30 días para no acumular costos
    }
    action {
      type = "Delete"
    }
  }

  storage_class = "STANDARD"
}

# 2. DATA WAREHOUSE: BigQuery Datasets (Capas de Datos)

# Capa RAW: Datos crudos (Tablas externas o ingesta directa)
resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id                 = "raw_london_energy"
  project                    = var.project
  location                   = var.location
  delete_contents_on_destroy = true
}

# Capa STAGING: Datos limpios/transformados con dbt o SQL
resource "google_bigquery_dataset" "stg_dataset" {
  dataset_id                 = "stg_london_energy"
  project                    = var.project
  location                   = var.location
  delete_contents_on_destroy = true
}

# Capa PRODUCTION: Datos finales para Dashboard o Análisis
resource "google_bigquery_dataset" "prod_dataset" {
  dataset_id                 = "prod_london_energy"
  project                    = var.project
  location                   = var.location
  delete_contents_on_destroy = true
}