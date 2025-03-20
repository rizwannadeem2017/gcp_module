resource "google_compute_firewall" "ssh_within_vpc" {
  project = google_project.ss-project.name
  name    = "allow-ssh-vpc"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = compact(concat(var.vpc_default_ports, coalesce(var.vpc_additional_ports, [])))
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}


resource "google_compute_network" "vpc_network" {
  description             = " ss-vpc-network"
  depends_on              = [null_resource.wait_for_api_enablement]
  project                 = google_project.ss-project.name
  name                    = "ss-vpc-network"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "subnets" {
  depends_on    = [null_resource.wait_for_api_enablement]
  description   = "${google_project.ss-project.name} vpc network subnets"
  project       = google_project.ss-project.name
  count         = length(var.subnet_names)
  name          = var.subnet_names[count.index]
  ip_cidr_range = var.cidr_blocks[count.index]
  region        = var.regions[count.index]
  network       = google_compute_network.vpc_network.id
  log_config {
    aggregation_interval = "INTERVAL_30_SEC"
    flow_sampling        = 0.5
    metadata             = "EXCLUDE_ALL_METADATA"
  }
}

resource "google_logging_project_sink" "vpc_flow_logs_sink" {
  depends_on  = [null_resource.wait_for_api_enablement]
  name        = "vpc-flow-logs-sink-${var.project_name}"
  project     = google_project.ss-project.name
  destination = "storage.googleapis.com/${google_storage_bucket.vpc_logs.name}"

  filter = <<EOT
  resource.type="gce_subnetwork"
  logName="projects/${google_project.ss-project.name}/logs/compute.googleapis.com%2Fvpc_flows"
  EOT

  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "log_sink_writer" {

  bucket = google_storage_bucket.vpc_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.vpc_flow_logs_sink.writer_identity
}
