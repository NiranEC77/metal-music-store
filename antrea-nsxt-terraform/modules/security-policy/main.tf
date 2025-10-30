# Security Policy Module
# Creates NSX-T security policy with Antrea integration

terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

resource "nsxt_policy_security_policy" "antrea_policy" {
  display_name    = var.policy_display_name
  description     = "Antrea-integrated security policy for ${var.policy_display_name}"
  category        = var.category
  domain          = var.domain
  sequence_number = var.sequence_number
  stateful        = var.stateful
  tcp_strict      = var.tcp_strict

  # Scope to the Antrea cluster control plane if provided
  scope = var.cluster_control_plane != "" ? ["/infra/sites/default/enforcement-points/default/cluster-control-planes/${var.cluster_control_plane}"] : null

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  tag {
    scope = "environment"
    tag   = "production"
  }
}

