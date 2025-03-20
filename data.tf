data "google_compute_zones" "available_zones" {
  region     = var.region
  project    = google_project.ss-project.name
  depends_on = [null_resource.wait_for_api_enablement]
}