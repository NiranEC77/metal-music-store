terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = ">= 3.4.0"
    }
  }
}

provider "nsxt" {
  host                 = var.nsxt_host
  username             = var.nsxt_username
  password             = var.nsxt_password
  allow_unverified_ssl = var.allow_unverified_ssl
}


