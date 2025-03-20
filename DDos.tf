
resource "google_compute_security_policy" "ddos_protection" {
  depends_on  = [null_resource.wait_for_api_enablement]
  project     = google_project.ss-project.name
  description = "test-dev-ddos-policy"
  name        = "test-dev-ddos-policy1"
  type        = "CLOUD_ARMOR"
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable          = true
      rule_visibility = null
    }
  }
  advanced_options_config {
    json_parsing = "STANDARD"
    log_level    = null
  }
  rule {
    action      = "allow"
    description = "Default rule, higher priority overrides it"
    preview     = false
    priority    = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
  rule {
    action      = "throttle"
    description = "Deny all traffic if brute force attack"
    preview     = false
    priority    = 2147483645
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      ban_duration_sec    = 0
      conform_action      = "allow"
      enforce_on_key      = null
      enforce_on_key_name = null
      exceed_action       = "deny(429)"
      rate_limit_threshold {
        count        = 200
        interval_sec = 60
      }
    }
  }
}
