resource "google_storage_bucket" "lb_logs" {
  project       = google_project.ss-project.name
  name          = var.lb_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  autoclass {
    enabled = true
  }
  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "db_logs" {
  project       = google_project.ss-project.name
  name          = var.db_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  autoclass {
    enabled = true
  }
  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "compute_logs" {
  project       = google_project.ss-project.name
  name          = var.compute_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  autoclass {
    enabled = true
  }
  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

}

resource "google_storage_bucket" "vpc_logs" {
  project       = google_project.ss-project.name
  name          = var.vpc_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  autoclass {
    enabled = true
  }
  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "app_storage" {
  project       = google_project.ss-project.name
  name          = var.app_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  autoclass {
    enabled = true
  }
  versioning {
    enabled = true
  }

}