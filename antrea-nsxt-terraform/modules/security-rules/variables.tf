variable "domain" {
  description = "NSX-T domain"
  type        = string
  default     = "default"
}

variable "policy_path" {
  description = "Path to the security policy"
  type        = string
}

variable "rules" {
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

variable "service_paths" {
  description = "Map of service names to their paths"
  type        = map(string)
  default     = {}
}

