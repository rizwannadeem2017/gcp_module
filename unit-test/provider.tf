provider "google" {
  credentials = var.google_credentials
  project     = "test1"
  region      = "europe-west1"
}

variable "google_credentials" {}