# Security Groups Module
# Creates NSX-T security groups for Kubernetes services

resource "nsxt_policy_group" "service_groups" {
  for_each = var.groups

  display_name = each.value.display_name
  description  = each.value.description
  domain       = var.domain

  dynamic "criteria" {
    for_each = each.value.criteria
    content {
      condition {
        member_type = criteria.value.member_type
        key         = criteria.value.key
        operator    = criteria.value.operator
        value       = criteria.value.value
      }
    }
  }
}

