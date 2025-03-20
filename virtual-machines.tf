
resource "google_compute_firewall" "allow_traffic" {
  project     = google_project.ss-project.name
  count       = var.instance_count ? 1 : 0
  name        = "${var.instance_name}-instance-firewall-rule"
  network     = google_compute_network.vpc_network.self_link
  source_tags = var.network_source_tags
  dynamic "allow" {
    for_each = var.instance_firewall_rule
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}

# fetch the latest ubuntu 22.04 LTS image which is build from packer image
# https://github.com/Simple-Sign-International-AB/packer-images

data "google_compute_image" "latest_baked_image" {
  project     = "turnkey-agility-149708"
  filter      = "name:baked-ubuntu-*"
  most_recent = true
}

resource "google_compute_instance" "ss-vm-instance" {
  depends_on   = [null_resource.wait_for_api_enablement]
  project      = google_project.ss-project.name
  count        = var.instance_count ? 1 : 0
  name         = var.instance_name
  machine_type = var.machine_type

  zone = data.google_compute_zones.available_zones.names[count.index % length(data.google_compute_zones.available_zones.names)]

  labels   = var.labels
  tags     = var.tags
  metadata = var.metadata

  boot_disk {
    auto_delete = true
    source      = google_compute_disk.boot_disk[0].id
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnets[0].self_link

    access_config {
      nat_ip       = google_compute_address.static-ip[count.index].address
      network_tier = "PREMIUM"
    }
  }

  attached_disk {
    source      = google_compute_disk.data_disk[count.index].id
    device_name = "data"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [metadata, attached_disk, boot_disk]
  }
}

resource "google_compute_address" "static-ip" {
  project = google_project.ss-project.name
  count   = var.instance_count ? 1 : 0
  name    = "${var.instance_name}-static-ip"
  region  = var.region
}

resource "google_compute_disk" "data_disk" {
  project = google_project.ss-project.name
  count   = var.instance_count ? 1 : 0
  name    = "${var.instance_name}-data-disk"
  size    = var.addtional_disk_size
  type    = "pd-ssd"
  zone    = data.google_compute_zones.available_zones.names[count.index % length(data.google_compute_zones.available_zones.names)]
  labels  = var.labels
  lifecycle {
    create_before_destroy = true
  }
  #   disk_encryption_key {
  #     kms_key_self_link = "projects/turnkey-agility-149708/locations/europe-west1/keyRings/vm-disk-encyption-key-key/cryptoKeys/vm-disk-encyption-key"
  #   }
}

resource "google_compute_disk" "boot_disk" {
  count   = var.instance_count ? 1 : 0
  name    = "${var.instance_name}-boot-disk"
  project = google_project.ss-project.name
  zone    = data.google_compute_zones.available_zones.names[count.index % length(data.google_compute_zones.available_zones.names)]
  type    = "pd-ssd"
  size    = var.default_disk_size
  image   = data.google_compute_image.latest_baked_image.self_link
  labels  = var.labels
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [image]
  }
}

resource "google_compute_instance_group" "ss-unmanaged_group" {
  count     = var.instance_count ? 1 : 0
  project   = google_project.ss-project.name
  name      = "${var.instance_name}-instance-group"
  zone      = data.google_compute_zones.available_zones.names[count.index % length(data.google_compute_zones.available_zones.names)]
  instances = [google_compute_instance.ss-vm-instance[0].self_link]

  named_port {
    name = "http"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 
resource "google_compute_disk_resource_policy_attachment" "instance_disk_daily_backup_policy_attachment" {
  count   = var.instance_count ? 1 : 0
  project = google_project.ss-project.name
  name    = google_compute_resource_policy.instance_disk_daily_backup_policy.name
  disk    = google_compute_disk.data_disk[0].name
  zone    = data.google_compute_zones.available_zones.names[count.index % length(data.google_compute_zones.available_zones.names)]
}

resource "google_compute_disk_resource_policy_attachment" "instance_boot_disk_daily_backup_policy_attachment" {
  count   = var.instance_count ? 1 : 0
  project = google_project.ss-project.name
  name    = google_compute_resource_policy.instance_disk_daily_backup_policy.name
  disk    = google_compute_disk.boot_disk[0].name
  zone    = data.google_compute_zones.available_zones.names[count.index % length(data.google_compute_zones.available_zones.names)]
}

resource "google_compute_resource_policy" "instance_disk_daily_backup_policy" {
  depends_on  = [null_resource.wait_for_api_enablement]
  description = "${google_project.ss-project.name}-instance-disk-daily-backup"
  project     = google_project.ss-project.name
  name        = "${google_project.ss-project.name}-instance-disk-daily-backup1"
  region      = var.region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
    retention_policy {
      max_retention_days    = 10
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      storage_locations = [var.region]
    }
  }
}

## Export lb logs to gcp bucket 
resource "google_logging_project_sink" "instance_logs_sink" {
  depends_on  = [null_resource.wait_for_api_enablement]
  name        = "vm-logs-sink"
  project     = google_project.ss-project.name
  destination = "storage.googleapis.com/${google_storage_bucket.compute_logs.name}"
  filter      = "resource.type = gce_instance AND resource.labels.instance_id = \"${google_compute_instance.ss-vm-instance[0].instance_id}\""

  unique_writer_identity = true
}

resource "google_project_iam_binding" "gcs-bucket-writer" {
  project    = google_project.ss-project.name
  depends_on = [null_resource.wait_for_api_enablement]
  role       = "roles/storage.objectCreator"

  members = [
    google_logging_project_sink.instance_logs_sink.writer_identity,
  ]
}