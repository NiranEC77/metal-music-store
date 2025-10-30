variable "domain" {
  description = "NSX-T domain"
  type        = string
  default     = "default"
}

variable "groups" {
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

