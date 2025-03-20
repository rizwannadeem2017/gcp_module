
### App engine application services can not be import with terraform although we can import app service version but that is managed by github actions

## For now we are managing dispatch_rules and domain mapping with terraform

resource "google_app_engine_application" "ss_frontend_app" {
  depends_on  = [null_resource.wait_for_api_enablement]
  project     = google_project.ss-project.name
  location_id = var.region

  lifecycle {
    ignore_changes = [location_id]
  }
}

resource "google_app_engine_application_url_dispatch_rules" "app_engine_dispatch_rule" {
  count   = var.create_app_engine_domain_mapping ? 1 : 0
  project = google_project.ss-project.name
  dispatch_rules {
    domain  = var.app_engine_domain_name
    path    = var.dispatch_rule_path
    service = var.app_engine_service_name
  }
}


resource "google_app_engine_domain_mapping" "app_engine_domain_mapping" {
  count       = var.create_app_engine_domain_mapping ? 1 : 0
  domain_name = var.app_engine_domain_name
  project     = google_project.ss-project.name
  ssl_settings {
    ssl_management_type = "AUTOMATIC"
  }
}



resource "google_app_engine_firewall_rule" "default" {
  depends_on   = [google_app_engine_application.ss_frontend_app]
  action       = var.firewall_rule.action
  description  = var.firewall_rule.description
  priority     = var.firewall_rule.priority
  project      = google_project.ss-project.name
  source_range = var.firewall_rule.source_range
}


