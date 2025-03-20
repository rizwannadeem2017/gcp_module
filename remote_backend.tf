terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Simple_sign"

    workspaces {
      name = "terraform-gpc-module"
    }
  }
}
