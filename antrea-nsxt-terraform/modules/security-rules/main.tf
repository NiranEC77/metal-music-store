# Security Rules Module
# Creates security rules within a policy

terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

resource "nsxt_policy_security_policy_rule" "rules" {
  for_each = { for idx, rule in var.rules : rule.display_name => rule }

  display_name       = each.value.display_name
  description        = each.value.description
  policy_path        = var.policy_path
  sequence_number    = each.value.sequence_number
  action             = each.value.action
  direction          = each.value.direction
  disabled           = each.value.disabled
  logged             = each.value.logged
  ip_version         = "IPV4_IPV6"

  # Source groups
  source_groups = [
    for group in each.value.source_groups :
    group == "ANY" ? "ANY" : "/infra/domains/${var.domain}/groups/${group}"
  ]

  # Destination groups
  destination_groups = [
    for group in each.value.destination_groups :
    group == "ANY" ? "ANY" : "/infra/domains/${var.domain}/groups/${group}"
  ]

  # Services - use ANY if specified, otherwise use the custom service
  services = length(each.value.services) > 0 && each.value.services[0] == "ANY" ? ["ANY"] : (
    each.value.service_name != "" ? [var.service_paths[each.value.service_name]] : []
  )

  # Scope - limit rule application to specific groups
  scope = [
    for group in each.value.scope_groups :
    group == "ANY" ? "ANY" : "/infra/domains/${var.domain}/groups/${group}"
  ]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

