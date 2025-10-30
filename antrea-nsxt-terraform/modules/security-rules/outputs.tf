output "rule_ids" {
  description = "Map of rule names to their IDs"
  value = {
    for k, v in nsxt_policy_security_policy_rule.rules : k => v.id
  }
}

output "rule_paths" {
  description = "Map of rule names to their paths"
  value = {
    for k, v in nsxt_policy_security_policy_rule.rules : k => v.path
  }
}

