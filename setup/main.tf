terraform {
  required_version = ">= 1.0"
  backend "gcs" {
    bucket = "diplomats-in-germany-xxxxxx-tf-state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  credentials = file(local.gcp_key_file)
}

# Data Lake Bucket
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "data-lake-bucket" {
  name                        = local.data_lake_bucket
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = false
  }
} 

# BigQuery DWH
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "datasets" {
  for_each    = var.bq_datasets
  dataset_id  = each.value
  location    = var.region
} 

# Airflow Docker Host
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_instance" "airflow-host" {
  name         = "airflow-host"
  machine_type = "e2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-v20220420"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${local.gce_ssh_user}:${file(local.gce_ssh_pub_key_file)}"
  }

  tags = ["ssh-server"]
}

resource "google_compute_network" "vpc_network" {
  name                    = "vpc-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "ssh-server" {
  name    = "default-allow-ssh-terraform"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  // Allow traffic from everywhere to instances with an ssh-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-server"]
}

output "ip" {
  value = "${google_compute_instance.airflow-host.network_interface.0.access_config.0.nat_ip}"
}
