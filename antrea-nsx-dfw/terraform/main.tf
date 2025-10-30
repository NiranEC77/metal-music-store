module "dfw" {
  source = "../modules/dfw"

  nsxt_host             = var.nsxt_host
  nsxt_username         = var.nsxt_username
  nsxt_password         = var.nsxt_password
  allow_unverified_ssl  = var.allow_unverified_ssl
}


