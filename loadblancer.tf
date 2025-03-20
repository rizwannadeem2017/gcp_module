#### Managed SSL Certificate 
resource "google_compute_managed_ssl_certificate" "google_managed_ssl" {
  depends_on = [null_resource.wait_for_api_enablement]
  project    = google_project.ss-project.name
  name       = "${google_project.ss-project.name}-backend-loadbalancer-certificate"
  type       = "MANAGED"

  managed {
    domains = var.ssl_domain_name
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_managed_ssl_certificate" "google_managed_admin_ssl" {
  count      = var.enable_lb_custom_url_map_rules ? 1 : 0
  depends_on = [null_resource.wait_for_api_enablement]
  project    = google_project.ss-project.name
  name       = "${google_project.ss-project.name}-admin-backend-loadbalancer-certificate"
  type       = "MANAGED"

  managed {
    domains = var.ssl_admin_domain_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

### SSL target proxy
resource "google_compute_target_https_proxy" "ssl_proxy" {
  project = google_project.ss-project.name
  name    = "lb-ssl-proxy"
  url_map = google_compute_url_map.lb_url_map.id
  ssl_certificates = concat(
    [google_compute_managed_ssl_certificate.google_managed_ssl.id],
    var.enable_lb_custom_url_map_rules ? [google_compute_managed_ssl_certificate.google_managed_admin_ssl[0].id] : []
  )
}

resource "google_compute_backend_service" "block_backend" {
  count                 = var.enable_lb_custom_url_map_rules ? 1 : 0
  project               = google_project.ss-project.name
  name                  = "block-backend"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  timeout_sec           = 30

  health_checks   = [google_compute_health_check.lb-backend-health-check.id]
  security_policy = google_compute_security_policy.ddos_protection.self_link

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}
### Loadblaancer backend configuration
resource "google_compute_backend_service" "lb_backend" {
  project               = google_project.ss-project.name
  name                  = "${var.instance_name}-lb-backend"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.lb-backend-health-check.id]
  security_policy       = google_compute_security_policy.ddos_protection.self_link

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  backend {
    group          = google_compute_instance_group.ss-unmanaged_group[0].id
    balancing_mode = "UTILIZATION"
  }
}

### Loadblaancer backend health check configuration
resource "google_compute_health_check" "lb-backend-health-check" {
  project            = google_project.ss-project.name
  name               = "lb-backend-health-check"
  check_interval_sec = 30
  timeout_sec        = 10

  http_health_check {
    port = 80
  }
}

### Loadblaancer frontend configuration

resource "google_compute_url_map" "lb_url_map" {
  depends_on      = [null_resource.wait_for_api_enablement]
  project         = google_project.ss-project.name
  name            = var.loadbalancer_name
  default_service = google_compute_backend_service.lb_backend.id

  # Rules for api.env.simplesign.io
  dynamic "host_rule" {
    for_each = var.enable_lb_custom_url_map_rules ? [1] : []
    content {
      hosts        = var.ssl_domain_name
      path_matcher = "api-routes"
    }
  }

  # Rules for admin.env.simplesign.io
  dynamic "host_rule" {
    for_each = var.enable_lb_custom_url_map_rules ? [1] : []
    content {
      hosts        = var.ssl_admin_domain_name
      path_matcher = "admin-routes"
    }
  }

  # Path matcher for admin
  dynamic "path_matcher" {
    for_each = var.enable_lb_custom_url_map_rules ? [1] : []
    content {
      name            = "admin-routes"
      default_service = google_compute_backend_service.lb_backend.id

      path_rule {
        paths   = var.whitelist_lb_admin_routes
        service = google_compute_backend_service.lb_backend.id
      }

      path_rule {
        paths = ["/"]
        url_redirect {
          redirect_response_code = "FOUND" # 302 Temporary Redirect
          strip_query            = false
          https_redirect         = true
          prefix_redirect        = "/admin/login"
        }
      }
    }
  }

  # Path matcher for API routes
  dynamic "path_matcher" {
    for_each = var.enable_lb_custom_url_map_rules ? [1] : []
    content {
      name            = "api-routes"
      default_service = google_compute_backend_service.lb_backend.id

      path_rule {
        paths = ["/admin/*", "/admin"]
        url_redirect {
          redirect_response_code = "FOUND" # 302 Temporary Redirect
          strip_query            = false
          https_redirect         = true
          path_redirect          = "/admin/login"
        }
      }

      path_rule {
        paths   = ["/*"]
        service = google_compute_backend_service.lb_backend.id
      }
    }
  }
}


### Loadblaancer frontend forwarding configuration
resource "google_compute_global_forwarding_rule" "https_rule" {
  project    = google_project.ss-project.name
  name       = "${var.loadbalancer_name}-lb-https-forwarding-rule"
  target     = google_compute_target_https_proxy.ssl_proxy.id
  port_range = "443"
}

## Export lb logs to gcp bucket 
resource "google_logging_project_sink" "lb_logs_sink" {
  depends_on  = [null_resource.wait_for_api_enablement]
  name        = "lb-logs-sink"
  project     = google_project.ss-project.name
  destination = "storage.googleapis.com/${google_storage_bucket.lb_logs.name}"

  filter = <<EOT
    resource.type="https_load_balancer"
    resource.labels.url_map_name="${google_compute_url_map.lb_url_map.name}"
  EOT

  unique_writer_identity = true
}

## Add bucket permissions
resource "google_project_iam_binding" "dbs-bucket-writer" {
  project    = google_project.ss-project.name
  depends_on = [null_resource.wait_for_api_enablement]
  role       = "roles/storage.objectCreator"

  members = [
    google_logging_project_sink.lb_logs_sink.writer_identity,
  ]
}
