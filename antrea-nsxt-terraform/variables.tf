# NSX-T Manager Connection Variables

variable "nsx_manager" {
  description = "NSX-T Manager hostname or IP address"
  type        = string
}

variable "nsx_username" {
  description = "NSX-T Manager username"
  type        = string
}

variable "nsx_password" {
  description = "NSX-T Manager password"
  type        = string
  sensitive   = true
}

variable "allow_unverified_ssl" {
  description = "Allow unverified SSL certificates"
  type        = bool
  default     = true
}

variable "cluster_control_plane_id" {
  description = "Antrea cluster control plane ID"
  type        = string
}
