output "group_paths" {
  description = "Map of group names to their paths"
  value = {
    for k, v in nsxt_policy_group.service_groups : k => v.path
  }
}

output "group_ids" {
  description = "Map of group names to their IDs"
  value = {
    for k, v in nsxt_policy_group.service_groups : k => v.id
  }
}

