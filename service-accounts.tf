# Create the service account for terraform
resource "google_service_account" "svc-terraform" {
  account_id   = "svc-terraform"
  display_name = "Terraform rizwan Service Account"
  project      = google_project.ss-project.name
}

# Assign Roles to the Service Account using for_each
resource "google_project_iam_member" "svc-terraform-roles" {
  for_each = toset(local.roles)

  project = google_project.ss-project.name
  role    = each.value
  member  = "serviceAccount:${google_service_account.svc-terraform.email}"
}

# Create the service account for github actions
resource "google_service_account" "svc-github-actions" {
  account_id   = "svc-github-actions"
  display_name = "Github Actions Service Account"
  project      = google_project.ss-project.name
}

# Assign Roles to the Service Account using for_each
resource "google_project_iam_member" "svc-github-actions-roles" {
  for_each = toset(local.roles)

  project = google_project.ss-project.name
  role    = each.value
  member  = "serviceAccount:${google_service_account.svc-github-actions.email}"
}

locals {
  roles = [
    "roles/compute.admin",
    "roles/compute.networkAdmin",
    "roles/compute.storageAdmin",
    "roles/compute.viewer",
    "roles/dns.admin",
    "roles/owner",
    "roles/cloudkms.admin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/cloudkms.viewer",
    "roles/billing.projectManager",
    "roles/iam.roleAdmin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/storage.objectAdmin",
    "roles/storage.objectViewer",
    "roles/viewer"
  ]
}