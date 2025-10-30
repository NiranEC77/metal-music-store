terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.0"
    }
  }
}

provider "nsxt" {
  host                 = var.nsx_manager
  username             = var.nsx_username
  password             = var.nsx_password
  allow_unverified_ssl = var.allow_unverified_ssl
}

# Create security groups for services
module "security_groups" {
  source = "./modules/security-groups"

  domain = var.domain
  groups = var.security_groups
}

# Create the main security policy
module "security_policy" {
  source = "./modules/security-policy"

  domain                 = var.domain
  policy_name            = var.policy_name
  policy_display_name    = var.policy_display_name
  category               = var.policy_category
  sequence_number        = var.policy_sequence_number
  stateful               = var.policy_stateful
  tcp_strict             = var.policy_tcp_strict
  cluster_control_plane  = var.cluster_control_plane_id
  scope_groups           = var.policy_scope_groups

  depends_on = [module.security_groups]
}

# Create security rules
module "security_rules" {
  source = "./modules/security-rules"

  domain      = var.domain
  policy_path = module.security_policy.policy_path
  rules       = var.security_rules

  depends_on = [module.security_policy, module.security_groups]
}

