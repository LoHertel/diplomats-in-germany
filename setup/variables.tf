locals {
  gcp_key_file           = "../credentials/terraform-gcp-key.json"
  project                = var.project
  region                 = var.region
  zone                   = var.zone
  name_suffix            = "${local.project}-${local.region}"
  data_lake_bucket       = "${local.name_suffix}-data-lake"
  gce_ssh_user           = "local"
  gce_ssh_pub_key_file   = "~/.ssh/id_rsa.pub"
  gce_ssh_priv_key_file  = "~/.ssh/id_rsa"
}

variable "project" {
  description = "Your GCP Project ID"
  type = string
}

variable "region" {
  description = "Region for GCP resources. Choose as per your location: https://cloud.google.com/storage/docs/locations#location-r"
  default = "europe-west1"
  type = string
}

variable "zone" {
  description = "Zone for GCP resources."
  default = "europe-west1-b"
  type = string
}

variable "storage_class" {
  description = "Storage class type for your bucket. Check official docs for more info."
  default = "STANDARD"
  type = string
}

variable "bq_datasets" {
  description = "BigQuery Datasets needed"
  default = ["staging", "raw_datavault", "datamart"]
  type = list(string)
}