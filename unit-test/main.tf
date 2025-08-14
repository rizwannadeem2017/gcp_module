module "test_run" {
  source = "../"


  ### GCP Project module validation ######
  ########################################
  project_id      = var.project_id
  project_name    = var.project_id
  region          = "europe-west1"
  billing_account = "01FC-AS1-Ad1-S"


  ##### vpc network ######
  ########################
  vpc_name             = "vpc-${var.project_id}"
  subnet_names         = ["europe-west1-a", "europe-west1-b", "europe-west1-c"]
  cidr_blocks          = ["10.0.1.0/24", "192.168.0.0/24", "10.0.4.0/24"]
  regions              = ["europe-west1", "europe-west2", "europe-west3"]
  vpc_additional_ports = [""]

  ##### Storage buckets #####
  ###########################

  lb_bucket_name      = "lb-logs-${var.project_id}-${random_id.bucket_suffix.hex}"
  db_bucket_name      = "db-logs-${var.project_id}-${random_id.bucket_suffix.hex}"
  compute_bucket_name = "vm-logs-${var.project_id}-${random_id.bucket_suffix.hex}"
  vpc_bucket_name     = "vpc-flow-logs-${var.project_id}-${random_id.bucket_suffix.hex}"
  app_bucket_name     = "app-test-${var.project_id}-${random_id.bucket_suffix.hex}"

  ### App Engine module validation ######
  #######################################

  app_engine_domain_name           = "test.rizwan.se"
  app_engine_service_name          = "default"
  dispatch_rule_path               = "/#/*"
  zone                             = "europe-west1-b"
  create_app_engine_domain_mapping = true
  firewall_rule = {
    action       = "ALLOW"
    description  = "The default action."
    priority     = 1000
    project      = var.project_id
    source_range = "*"
  }


  ### Database Mysql details module validation #####
  ###################################################
  create_managed_sql         = true
  database_instance_name     = "rizwanio-db123a"
  database_database_name     = "rizwan-db-1xqq"
  database_tier              = "db-custom-2-8192"
  database_disk_size         = "100"
  database_password          = "MyS3curePa$$w0rd!"
  database_username          = "rizwanio"
  database_protection_enable = false
  enable_db_publicIP         = false
  whitelist_db_authorized_ip = ""

  ### loadbalancer ############
  #############################
  loadbalancer_name              = "test-lb"
  enable_lb_custom_url_map_rules = false
  whitelist_lb_admin_routes      = ["/admin/login/*", "/nova-api", "/nova-api/", "/nova-api/*", "/horizon/*", "/log-viewer/*", "/telescope/*"]
  ssl_domain_name                = ["test.rizwan.io"]
  ssl_admin_domain_name          = ["admin.test.rizwan.io"]


  ### Virtual machine module validation ###########
  ################################################
  instance_count = "1"
  instance_name  = local.labels.name
  machine_type   = "e2-medium"

  addtional_disk_size = "100"
  default_disk_size   = "100"
  labels              = local.labels
  tags                = ["backend"]
  network_source_tags = ["vm-firewall-rule"]
  metadata = {
    "startup-script" = file("../volume.sh")
  }
}

########## locals ######
########################
locals {
  labels = {
    name        = "virtual-machine-01"
    application = "backend"
    client_name = "test"
    project_id  = var.project_id
  }
}

#### Random_id for bucket suffix #####
######################################
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
