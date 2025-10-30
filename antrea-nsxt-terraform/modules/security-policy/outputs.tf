output "policy_id" {
  description = "Security policy ID"
  value       = nsxt_policy_security_policy.antrea_policy.id
}

output "policy_path" {
  description = "Security policy path"
  value       = nsxt_policy_security_policy.antrea_policy.path
}

output "policy_revision" {
  description = "Security policy revision"
  value       = nsxt_policy_security_policy.antrea_policy.revision
}

