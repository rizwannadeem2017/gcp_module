
# Simeple Sign Cloud SQL High CPU Alert
resource "google_monitoring_alert_policy" "db_high_cpu" {
  count        = var.create_managed_sql ? 1 : 0
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} Cloud SQL High CPU Usage Alert"

  conditions {
    display_name = "Project: ${google_project.ss-project.name} Cloud SQL CPU Utilization"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" AND resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${google_sql_database_instance.mysql_instance[0].name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8 # Alert when CPU utilization > 80%
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.id]
  combiner              = "OR"
  enabled               = true
}

# Simeple Sign Cloud SQL High Storage Alert
resource "google_monitoring_alert_policy" "db_high_storage" {
  count        = var.create_managed_sql ? 1 : 0
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} Cloud SQL High Storage Usage Alert"

  conditions {
    display_name = "Project: ${google_project.ss-project.name} Cloud SQL Storage Usage"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/disk/utilization\" AND resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${google_sql_database_instance.mysql_instance[0].name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8 # Alert when storage utilization > 80%
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.id]
  combiner              = "OR"
  enabled               = true
}

# Simeple Sign Cloud SQL High Memory Alert
resource "google_monitoring_alert_policy" "db_high_memory" {
  count        = var.create_managed_sql ? 1 : 0
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} Cloud SQL High Memory Usage Alert"

  conditions {
    display_name = "Project: ${google_project.ss-project.name} Cloud SQL Memory Usage"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/memory/utilization\" AND resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${google_sql_database_instance.mysql_instance[0].name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.75 # Alert when memory utilization > 75%
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.id]
  combiner              = "OR"
  enabled               = true
}

# # Slow Query Alert Policy
# resource "google_monitoring_alert_policy" "slow_query_alert" {
#   project      = google_project.ss-project.name
#   display_name = " Project: ${google_project.ss-project.name} Cloud SQL Slow Query Alert"

#    conditions {
#     display_name = "Project: ${google_project.ss-project.name} Slow Queries Detected"
#     condition_threshold {
#       filter = <<EOT
#         metric.type="logging.googleapis.com/user/mysql-slow-queries"
#         AND resource.type="cloudsql_database"
#       EOT
#       comparison      = "COMPARISON_GT"
#       threshold_value = 2  # Alert when more than 2 slow queries occur in 1 minute
#       duration        = "60s"
#       aggregations {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_SUM"
#       }
#     }
#   }

#   notification_channels = [google_monitoring_notification_channel.google_chat.id]  # ✅ Send alerts to Google Chat
#   combiner             = "OR"
#   enabled              = true
# }


# # Cloud SQL Database Deletion Alert
# resource "google_monitoring_alert_policy" "database_deletion_alert" {
#   project      = google_project.ss-project.name
#   display_name = "Project: ${google_project.ss-project.name} Cloud SQL Database Deletion Alert"

#   conditions {
#     display_name = "Project: ${google_project.ss-project.name} Database Deletion Detected"
#     condition_threshold {
#       filter = <<EOT
#         metric.type="logging.googleapis.com/user/database-deletion-events"
#         AND resource.type="cloudsql_database"
#       EOT
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0
#       duration        = "60s"
#       aggregations {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_SUM"
#       }
#     }
#   }

#   notification_channels = [google_monitoring_notification_channel.google_chat.id]
#   combiner             = "OR"
#   enabled              = true
# }


# ########### Google logging metrics

# # Create a log-based metric for MySQL slow queries
# resource "google_logging_metric" "mysql_slow_query_metric" {
#   name        = "Project: ${google_project.ss-project.name} - ${var.database_instance_name} - mysql-slow-queries"
#   project     = google_project.ss-project.name
#   filter      = <<EOT
#     resource.type = "cloudsql_database"
#     AND resource.labels.database_id="${google_sql_database_instance.mysql_instance.name}"
#     AND logName="projects/${google_project.ss-project.name}/logs/cloudsql.googleapis.com%2Fmysql-slow.log"
#   EOT
#   metric_descriptor {
#     metric_kind = "DELTA"
#     value_type  = "INT64"
#   }
# }

# # Create a log-based metric for Cloud SQL database deletions
# resource "google_logging_metric" "database_deletion_metric" {
#   name        = "Project: ${google_project.ss-project.name} - ${var.database_instance_name} database-deletion-events"
#   project     = google_project.ss-project.name
#   filter      = <<EOT
#     resource.type = "cloudsql_database"
#     AND resource.labels.database_id="${google_sql_database_instance.mysql_instance.name}"
#     AND logName="projects/${google_project.ss-project.name}/logs/cloudaudit.googleapis.com%2Factivity"
#     AND protoPayload.methodName="cloudsql.instances.delete"
#   EOT
#   metric_descriptor {
#     metric_kind = "DELTA"
#     value_type  = "INT64"
#   }
# }