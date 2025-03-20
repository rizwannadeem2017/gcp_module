resource "google_project_service" "enable_service_usage" {
  project            = google_project.ss-project.project_id
  service            = "serviceusage.googleapis.com"
  disable_on_destroy = false
  timeouts {
    create = "5m"
    update = "6m"
  }
}

resource "google_project_service" "enable_apis" {
  for_each = toset(var.api_services)
  project  = google_project.ss-project.project_id
  service  = each.key

  timeouts {
    create = "6m"
    update = "8m"
  }

  depends_on = [
    google_project_service.enable_service_usage
  ]
}
variable "api_services" {
  description = "List of Google Cloud APIs to enable"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "dns.googleapis.com",
    "container.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "iamcredentials.googleapis.com",
    "securitycenter.googleapis.com",
    "cloudsupport.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
    "appengine.googleapis.com",
    "appenginereporting.googleapis.com",
    "appengineflex.googleapis.com",
    "certificatemanager.googleapis.com"
  ]
}

resource "null_resource" "wait_for_api_enablement" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [google_project_service.enable_apis]
}