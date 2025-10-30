resource "nsxt_policy_security_policy" "prod" {
  display_name = "prod"
  path         = "/infra/domains/default/security-policies/prod"
  category     = "Application"
  stateful     = true
}


