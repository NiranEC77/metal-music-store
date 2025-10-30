# Security Policy Module
# Creates NSX-T security policy with Antrea integration

resource "nsxt_policy_security_policy" "antrea_policy" {
  display_name    = var.policy_display_name
  description     = "Antrea-integrated security policy for ${var.policy_display_name}"
  category        = var.category
  domain          = var.domain
  sequence_number = var.sequence_number
  stateful        = var.stateful
  tcp_strict      = var.tcp_strict

  # Scope to specific groups if provided
  dynamic "scope" {
    for_each = length(var.scope_groups) > 0 ? [1] : []
    content {
      paths = var.scope_groups
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  tag {
    scope = "environment"
    tag   = "production"
  }
}

# Associate the policy with the Antrea cluster
resource "nsxt_policy_predefined_security_policy" "cluster_binding" {
  count = var.cluster_control_plane != "" ? 1 : 0

  path                    = nsxt_policy_security_policy.antrea_policy.path
  default_rule_logging    = false
  
  # Scope to the Antrea cluster control plane
  scope = ["/infra/sites/default/enforcement-points/default/cluster-control-planes/${var.cluster_control_plane}"]
}

