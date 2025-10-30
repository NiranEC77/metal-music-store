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

variable "domain" {
  description = "NSX-T domain"
  type        = string
  default     = "default"
}

variable "policy_name" {
  description = "Security policy name"
  type        = string
  default     = "prod"
}

variable "policy_display_name" {
  description = "Security policy display name"
  type        = string
  default     = "music-store-prod"
}

variable "policy_category" {
  description = "Security policy category"
  type        = string
  default     = "Application"
}

variable "policy_sequence_number" {
  description = "Security policy sequence number"
  type        = number
  default     = 499999
}

variable "policy_stateful" {
  description = "Enable stateful firewall"
  type        = bool
  default     = true
}

variable "policy_tcp_strict" {
  description = "Enable TCP strict mode"
  type        = bool
  default     = true
}

variable "cluster_control_plane_id" {
  description = "Antrea cluster control plane ID"
  type        = string
}

variable "policy_scope_groups" {
  description = "Groups in scope for the security policy"
  type        = list(string)
  default     = []
}

variable "custom_services" {
  description = "Map of custom services to create"
  type = map(object({
    description       = string
    protocol          = string
    destination_ports = list(string)
  }))
  default = {}
}

variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    display_name = string
    description  = string
    criteria = list(object({
      member_type = string
      key         = string
      operator    = string
      value       = string
    }))
  }))
}

variable "security_rules" {
  description = "List of security rules to create"
  type = list(object({
    display_name         = string
    description          = string
    action               = string
    sequence_number      = number
    source_groups        = list(string)
    destination_groups   = list(string)
    services             = list(string)
    service_name         = string
    scope_groups         = list(string)
    direction            = string
    logged               = bool
    disabled             = bool
  }))
}

