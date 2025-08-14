terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Rizwan-org"

    workspaces {
      name = "terraform-gpc-module"
    }
  }
}
