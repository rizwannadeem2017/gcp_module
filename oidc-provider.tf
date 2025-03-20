resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = google_project.ss-project.project_id
  depends_on                = [null_resource.wait_for_api_enablement]
  workload_identity_pool_id = "github-oidc-poll"
  display_name              = "GitHub Workload Identity Pool"
  description               = "Pool for GitHub OIDC Authentication"
  disabled                  = false
}


resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = google_project.ss-project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "SS GitHub OIDC Provider"
  description                        = "SS OIDC Provider for GitHub Actions"

  attribute_mapping = {
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "google.subject"       = "assertion.sub"
  }

  attribute_condition = "attribute.repository.matches('your_repo/*')"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Bind IAM Role to allow GitHub Actions to impersonate the service account
resource "google_service_account_iam_binding" "github_sa_binding" {
  service_account_id = google_service_account.svc-github-actions.id
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/your_repo/rizwan_V3_angular",
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/your_repo/v3.rizwanbackend"

  ]
}