output "service_paths" {
  description = "Map of service names to their paths"
  value = {
    for k, v in nsxt_policy_service.custom_services : k => v.path
  }
}

output "service_ids" {
  description = "Map of service names to their IDs"
  value = {
    for k, v in nsxt_policy_service.custom_services : k => v.id
  }
}

