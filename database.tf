
resource "google_compute_firewall" "mysql_firewall" {
  count   = var.create_managed_sql ? 1 : 0
  project = google_project.ss-project.name
  name    = "allow-mysql-private1"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = var.cidr_blocks     # Only allow private IPs
  target_tags   = ["mysql-access-vm"] # Restrict access to VMs with this tag

  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}



# Allocate an IP range for the Cloud SQL instance
resource "google_compute_global_address" "private_ip_address" {
  count         = var.create_managed_sql ? 1 : 0
  depends_on    = [null_resource.wait_for_api_enablement]
  project       = google_project.ss-project.name
  name          = "mysql-db-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Create a private connection for the VPC network
resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.create_managed_sql ? 1 : 0
  depends_on              = [null_resource.wait_for_api_enablement]
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

resource "google_sql_database_instance" "mysql_instance" {

  depends_on = [google_service_networking_connection.private_vpc_connection]

  project             = google_project.ss-project.name
  count               = var.create_managed_sql ? 1 : 0
  name                = var.database_instance_name
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = var.database_tier
    disk_size         = var.database_disk_size
    disk_autoresize   = true
    disk_type         = "PD_SSD"
    availability_type = "REGIONAL"
    # edition  = "ENTERPRISE_PLUS"

    deletion_protection_enabled = var.database_protection_enable

    backup_configuration {
      enabled                        = true
      binary_log_enabled             = true
      start_time                     = "02:00"
      location                       = var.region
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = "7"
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = var.enable_db_publicIP
      private_network = google_compute_network.vpc_network.self_link
      # require_ssl     = true 
      dynamic "authorized_networks" {
        for_each = length(var.whitelist_db_authorized_ip) > 0 ? [var.whitelist_db_authorized_ip] : []
        content {
          name  = "allow-db-authorized-ip"
          value = authorized_networks.value
        }
      }
    }

    database_flags {
      name  = "log_bin_trust_function_creators"
      value = "on"
    }

    database_flags {
      name  = "long_query_time"
      value = "20" # Logs queries taking longer than 2 seconds
    }
    database_flags {
      name  = "max_connections"
      value = "1000"
    }
    database_flags {
      name  = "general_log"
      value = "on"
    }
    database_flags {
      name  = "log_output"
      value = "FILE"
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }
    # database_flags {
    #   name  = "require_secure_transport"
    #   value = "on"
    # }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    # password_validation_policy {
    #   min_length                  = 12
    #   # complexity                  = "COMPLEXITY_DEFAULT"
    #   disallow_username_substring = true
    #   enable_password_policy      = true

    # }
  }
}

resource "google_sql_database" "default" {
  count    = var.create_managed_sql ? 1 : 0
  project  = google_project.ss-project.name
  name     = var.database_database_name
  instance = google_sql_database_instance.mysql_instance[0].name
}

resource "google_sql_user" "db_user" {
  count    = var.create_managed_sql ? 1 : 0
  project  = google_project.ss-project.name
  name     = var.database_username
  instance = google_sql_database_instance.mysql_instance[0].name
  password = var.database_password
}



resource "google_logging_project_sink" "mysql_logs_sink" {
  count                  = var.create_managed_sql ? 1 : 0
  project                = google_project.ss-project.name
  name                   = "mysql-logs-sink"
  destination            = "storage.googleapis.com/${google_storage_bucket.db_logs.name}"
  filter                 = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${google_sql_database_instance.mysql_instance[0].name}\""
  unique_writer_identity = true
  depends_on             = [null_resource.wait_for_api_enablement]
}

resource "google_storage_bucket_iam_member" "logs_bucket_iam" {
  count      = var.create_managed_sql ? 1 : 0
  bucket     = google_storage_bucket.db_logs.name
  role       = "roles/storage.objectCreator"
  member     = google_logging_project_sink.mysql_logs_sink[0].writer_identity
  depends_on = [null_resource.wait_for_api_enablement]
}