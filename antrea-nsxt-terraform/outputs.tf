output "security_policy_id" {
  description = "The ID of the created security policy"
  value       = module.security_policy.policy_id
}

output "security_policy_path" {
  description = "The path of the created security policy"
  value       = module.security_policy.policy_path
}

output "custom_services" {
  description = "Map of created custom service names to their paths"
  value       = module.services.service_paths
}

output "security_groups" {
  description = "Map of created security group names to their paths"
  value       = module.security_groups.group_paths
}

output "security_rules" {
  description = "Map of created security rule names to their paths"
  value       = module.security_rules.rule_paths
}

output "cluster_id" {
  description = "The Antrea cluster control plane ID"
  value       = var.cluster_control_plane_id
}

