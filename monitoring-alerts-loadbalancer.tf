resource "google_monitoring_alert_policy" "high_backend_latency" {
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} - ${var.loadbalancer_name} - High Backend Latency"
  combiner     = "OR"

  conditions {
    display_name = "Project: ${google_project.ss-project.name} - ${var.loadbalancer_name} - High Backend Latency"

    condition_threshold {
      filter          = <<-EOT
        metric.type="loadbalancing.googleapis.com/https/backend_latencies"
        resource.type="https_lb_rule"
        resource.label."url_map_name"="${google_compute_url_map.lb_url_map.name}"
      EOT
      comparison      = "COMPARISON_GT"
      threshold_value = 1000   # 1 second in milliseconds
      duration        = "300s" # 5 minutes
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99" # Use percentile for distribution metrics
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.name]
}

# Alert for High Backend Error Rate
# resource "google_monitoring_alert_policy" "high_backend_error_rate" {
#   project      = google_project.ss-project.name
#   display_name = "Project: ${google_project.ss-project.name} - ${var.loadbalancer_name} - High Backend Error Rate"
#   combiner     = "OR"

#   conditions {
#     display_name = "Project: ${google_project.ss-project.name} - ${var.loadbalancer_name} - High Backend Error Rate"

#     condition_threshold {
#       filter          = <<-EOT
#         metric.type="loadbalancing.googleapis.com/https/backend_request_count"
#         resource.type="https_lb_rule"
#         resource.label."url_map_name"="${google_compute_url_map.lb_url_map.name}"
#       EOT
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0.5
#       duration        = "300s" # 5 minutes
#       aggregations {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_RATE" # Use rate for count metrics
#       }
#     }
#   }

#   notification_channels = [google_monitoring_notification_channel.google_chat.name]
# }



# # Alert for High 5xx Error Rate
# resource "google_monitoring_alert_policy" "high_5xx_error_rate" {
#   project      = google_project.ss-project.name
#   display_name = "Project: ${google_project.ss-project.name} - ${var.loadbalancer_name} - High 5xx Error Rate"
#   combiner     = "OR"

#   conditions {
#     display_name = "Project: ${google_project.ss-project.name} - ${var.loadbalancer_name} - High 5xx Error Rate"

#     condition_threshold {
#       filter     = <<-EOT
#         metric.type="loadbalancing.googleapis.com/https/request_count"
#         resource.type="http_load_balancer"
#         resource.label.url_map_name="${google_compute_url_map.lb_url_map.name}"
#         metric.label.response_code_class=\"5xx\"
#       EOT
#       comparison = "COMPARISON_GT"
#       threshold_value = 10  # Alert if more than 10 requests result in 5xx errors within 5 minutes
#       duration        = "300s"  # 5 minutes
#       aggregations {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_RATE"  # Use rate for count metrics
#       }
#     }
#   }

#   notification_channels = [google_monitoring_notification_channel.google_chat.name]
# }