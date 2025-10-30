# Services Module
# Creates NSX-T services for custom port definitions

terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

resource "nsxt_policy_service" "custom_services" {
  for_each = var.services

  display_name = each.key
  description  = each.value.description

  l4_port_set_entry {
    display_name      = each.key
    protocol          = each.value.protocol
    destination_ports = each.value.destination_ports
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

