# Simeple Sign Google Chat Notification Channel
resource "google_monitoring_notification_channel" "google_chat" {
  project      = google_project.ss-project.name
  display_name = "Project: ${google_project.ss-project.name} Google Chat - Alerts"
  type         = "google_chat"

  labels = {
    space = "spaces/AAAAp3JUav8"
  }
}