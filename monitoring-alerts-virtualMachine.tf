# CPU Utilization Alert
resource "google_monitoring_alert_policy" "cpu_utilization_alert" {
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - High CPU Utilization"
  combiner     = "OR"

  conditions {
    display_name = "Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - CPU Utilization > 80%"

    condition_threshold {
      filter          = <<EOT
        metric.type="compute.googleapis.com/instance/cpu/utilization"
        AND resource.type="gce_instance"
        AND resource.labels.instance_id="${google_compute_instance.ss-vm-instance[0].instance_id}"
      EOT
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.id]
}

# Memory Utilization Alert
resource "google_monitoring_alert_policy" "memory_utilization_alert" {
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - High Memory Utilization"
  combiner     = "OR"

  conditions {
    display_name = "Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - Memory Utilization > 80%"

    condition_threshold {
      filter          = <<EOT
        metric.type="agent.googleapis.com/memory/percent_used"
        AND resource.type="gce_instance"
        AND resource.labels.instance_id="${google_compute_instance.ss-vm-instance[0].instance_id}"
      EOT
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s" # 5 minutes

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.id]
}

# Disk Utilization Alert
resource "google_monitoring_alert_policy" "disk_utilization_alert" {
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - High Disk Utilization"
  combiner     = "OR"

  conditions {
    display_name = " Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - Disk Utilization > 80%"

    condition_threshold {
      filter          = <<EOT
        metric.type="agent.googleapis.com/disk/percent_used"
        AND resource.type="gce_instance"
        AND resource.labels.instance_id="${google_compute_instance.ss-vm-instance[0].instance_id}"
      EOT
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "120s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.id]
}

# Uptime Check Alert
resource "google_monitoring_alert_policy" "uptime_check_alert" {
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - Instance Down"
  combiner     = "OR"

  conditions {
    display_name = "Project: ${google_project.ss-project.name} - Instance Name: ${var.instance_name} - Uptime Check Failed"

    condition_threshold {
      filter          = <<EOT
        metric.type="monitoring.googleapis.com/uptime_check/check_passed"
        AND resource.type="gce_instance"
        AND resource.labels.instance_id="${google_compute_instance.ss-vm-instance[0].instance_id}"
      EOT
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "60s" # 1 minute

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.id]
}