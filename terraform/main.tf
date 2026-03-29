terraform {
  required_version = ">= 1.0"
  backend "local" {} # You can change this to "gcs" later if you want to store the state in the cloud
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
  name          = "${var.gcs_bucket_name}_${var.project}" # Unique name
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 30 # Auto-cleanup after 30 days to avoid accumulating costs
    }
    action {
      type = "Delete"
    }
  }

  storage_class = "STANDARD"
}

# 2. DATA WAREHOUSE: BigQuery Datasets (Data Layers)

# RAW Layer: Raw data (External tables or direct ingestion)
resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id                 = "raw_london_energy"
  project                    = var.project
  location                   = var.location
  delete_contents_on_destroy = true
}

# STAGING Layer: Clean/transformed data with dbt or SQL
resource "google_bigquery_dataset" "stg_dataset" {
  dataset_id                 = "stg_london_energy"
  project                    = var.project
  location                   = var.location
  delete_contents_on_destroy = true
}

# PRODUCTION Layer: Final data for Dashboard or Analysis
resource "google_bigquery_dataset" "prod_dataset" {
  dataset_id                 = "prod_london_energy"
  project                    = var.project
  location                   = var.location
  delete_contents_on_destroy = true
}