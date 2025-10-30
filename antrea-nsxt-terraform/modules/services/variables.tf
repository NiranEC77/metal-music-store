variable "services" {
  description = "Map of services to create"
  type = map(object({
    description       = string
    protocol          = string
    destination_ports = list(string)
  }))
  default = {}
}

