variable "google_credentials" {
  default = ""
}

######  GCP project variables #######
#####################################
variable "org_id" {
  default = ""
}
variable "project_id" {}
variable "project_name" {}
variable "billing_account" {}


##### Storage buckets #####
###########################

variable "lb_bucket_name" {}
variable "compute_bucket_name" {}
variable "db_bucket_name" {}
variable "vpc_bucket_name" {}
variable "app_bucket_name" {}

### App Engine ##########
#########################

variable "firewall_rule" {
  type = object({
    action       = string
    description  = string
    priority     = number
    project      = string
    source_range = string
  })
}

variable "app_engine_domain_name" {}
variable "dispatch_rule_path" {}
variable "app_engine_service_name" {}
variable "create_app_engine_domain_mapping" {
  type    = bool
  default = false
}

### Virtual machine & loadblancer ########
##########################################

variable "instance_count" {}
variable "machine_type" {}
variable "instance_name" {}
variable "loadbalancer_name" {}
variable "enable_lb_custom_url_map_rules" {}
variable "whitelist_lb_admin_routes" {}
variable "ssl_domain_name" {}
variable "ssl_admin_domain_name" {}
variable "network_source_tags" {}
variable "default_disk_size" {}
variable "addtional_disk_size" {}
variable "region" {}
variable "zone" {}
variable "metadata" {
  default = ""
}
variable "labels" {
  default = ""
}
variable "tags" {
  default = ""
}

variable "instance_firewall_rule" {
  description = "List of allowed ports"
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = [
    { protocol = "tcp", ports = ["22", "80", "443"] },
    { protocol = "udp", ports = ["53"] }
  ]
}



## Database variables ######
############################
variable "create_managed_sql" {}
variable "database_tier" {}
variable "database_disk_size" {}
variable "database_protection_enable" {}
variable "database_database_name" {}
variable "database_instance_name" {
  sensitive = true
}
variable "database_password" {
  sensitive = true
}
variable "database_username" {
  sensitive = true
}
variable "enable_db_publicIP" {
  default = false
}
variable "whitelist_db_authorized_ip" {
  default = ""
}

### VPC Network variables #####
###############################

variable "vpc_name" {}
variable "subnet_names" {
  description = "Names of the subnets"
  type        = list(string)
}

variable "cidr_blocks" {
  description = "CIDR ranges for the subnets"
  type        = list(string)
}

variable "regions" {
  description = "Regions for the subnets"
  type        = list(string)
}

variable "vpc_additional_ports" {}
variable "vpc_default_ports" {
  default = ["22", "443", "80", "83"]
}