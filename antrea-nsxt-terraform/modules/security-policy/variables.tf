variable "domain" {
  description = "NSX-T domain"
  type        = string
  default     = "default"
}

variable "policy_name" {
  description = "Security policy name (ID)"
  type        = string
}

variable "policy_display_name" {
  description = "Security policy display name"
  type        = string
}

variable "category" {
  description = "Security policy category"
  type        = string
  default     = "Application"
}

variable "sequence_number" {
  description = "Security policy sequence number"
  type        = number
}

variable "stateful" {
  description = "Enable stateful firewall"
  type        = bool
  default     = true
}

variable "tcp_strict" {
  description = "Enable TCP strict mode"
  type        = bool
  default     = true
}

variable "cluster_control_plane" {
  description = "Antrea cluster control plane ID"
  type        = string
  default     = ""
}

variable "scope_groups" {
  description = "Groups in scope for the security policy"
  type        = list(string)
  default     = []
}

