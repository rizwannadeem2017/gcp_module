

variable "users" {
  description = "List of users to be added to the project"
  type        = list(string)
  default = [
    "rizwan@test.io"
  ]
}

variable "roles" {
  description = "List of IAM roles to assign to users"
  type        = list(string)
  default = [
    "roles/cloudasset.owner",
    "roles/dns.admin",
    # "roles/cloudbuild.editor",
    "roles/cloudkms.admin",
    "roles/cloudsql.admin",
    "roles/compute.admin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/resourcemanager.organizationAdmin",
    "roles/owner",
    "roles/billing.projectManager",
    "roles/resourcemanager.projectIamAdmin",
    "roles/riskmanager.admin",
    "roles/riskmanager.editor",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/cloudsupport.techSupportEditor",
    "roles/cloudsupport.techSupportViewer",
    "roles/iam.workloadIdentityUser"
  ]
}


resource "google_project_iam_member" "user_roles" {
  for_each = {
    for pair in flatten([
      for user in var.users : [
        for role in var.roles : {
          user = user
          role = role
        }
      ]
    ]) : "${pair.user}-${pair.role}" => pair
  }

  project    = google_project.ss-project.name
  role       = each.value.role
  member     = "user:${each.value.user}"
  depends_on = [null_resource.wait_for_api_enablement]
}