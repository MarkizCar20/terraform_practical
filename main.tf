terraform {
  required_providers {
    google = {
        source = "hashicorp/google"
        version = "4.51.0"
    }
  }
}

provider "google" {
  project = var.project_id
  credentials = file(var.project_credentials)

  region = var.project_region
}

module "network" {
  source = "./modules/network"
}

module "compute" {
  source = "./modules/compute"

  network_self_link = module.network.network_self_link
}