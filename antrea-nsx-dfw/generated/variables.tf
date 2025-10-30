variable "nsxt_host" { type = string }
variable "nsxt_username" { type = string }
variable "nsxt_password" { type = string, sensitive = true }
variable "allow_unverified_ssl" { type = bool, default = true }


