terraform {
  required_version = ">= 1.0"
  backend "gcs" {}  # Can change from "local" to "gcs" (for google), if you would like to preserve your tf-state online
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  // credentials = file(var.credentials)  # Use this if you do not want to set env-var GOOGLE_APPLICATION_CREDENTIALS
}

# Data Lake Bucket
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "data-lake-bucket" {
  name                        = "${var.project}-data-lake" # Concatenating DL bucket & Project name for unique naming
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}

# DWH
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "datasets" {
  for_each    = var.BQ_DATASETS
  dataset_id  = each.value
  location    = var.region
}

