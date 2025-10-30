terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = ">= 3.4.0"
    }
  }
}

provider "nsxt" {
  host                 = var.nsxt_host
  username             = var.nsxt_username
  password             = var.nsxt_password
  allow_unverified_ssl = var.allow_unverified_ssl
}

# Services (ports)
resource "nsxt_policy_service" "svc_tcp_5000" {
  display_name = "svc_tcp_5000"
  service_entry {
    display_name      = "TCP 5000"
    l4_protocol       = "TCP"
    destination_ports = ["5000"]
    resource_type     = "L4PortSetServiceEntry"
  }
}
resource "nsxt_policy_service" "svc_tcp_5001" {
  display_name = "svc_tcp_5001"
  service_entry {
    display_name      = "TCP 5001"
    l4_protocol       = "TCP"
    destination_ports = ["5001"]
    resource_type     = "L4PortSetServiceEntry"
  }
}
resource "nsxt_policy_service" "svc_tcp_5002" {
  display_name = "svc_tcp_5002"
  service_entry {
    display_name      = "TCP 5002"
    l4_protocol       = "TCP"
    destination_ports = ["5002"]
    resource_type     = "L4PortSetServiceEntry"
  }
}
resource "nsxt_policy_service" "svc_tcp_5003" {
  display_name = "svc_tcp_5003"
  service_entry {
    display_name      = "TCP 5003"
    l4_protocol       = "TCP"
    destination_ports = ["5003"]
    resource_type     = "L4PortSetServiceEntry"
  }
}
resource "nsxt_policy_service" "svc_tcp_5432" {
  display_name = "svc_tcp_5432"
  service_entry {
    display_name      = "TCP 5432"
    l4_protocol       = "TCP"
    destination_ports = ["5432"]
    resource_type     = "L4PortSetServiceEntry"
  }
}

# Groups (label-based)
resource "nsxt_policy_group" "store_service" {
  display_name = "store-service"
  path         = "/infra/domains/default/groups/store-service"
  criteria {
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "service-name:store"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "app-name:music-store"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "env:prod"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "namespace:name:music-store"
    }
  }
}
resource "nsxt_policy_group" "cart_service" {
  display_name = "cart-service"
  path         = "/infra/domains/default/groups/cart-service"
  criteria {
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "service-name:cart"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "app-name:music-store"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "env:prod"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "namespace:name:music-store"
    }
  }
}
resource "nsxt_policy_group" "order_service" {
  display_name = "order-service"
  path         = "/infra/domains/default/groups/order-service"
  criteria {
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "service-name:order"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "app-name:music-store"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "env:prod"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "namespace:name:music-store"
    }
  }
}
resource "nsxt_policy_group" "users_service" {
  display_name = "users-service"
  path         = "/infra/domains/default/groups/users-service"
  criteria {
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "service-name:users"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "app-name:music-store"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "env:prod"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "namespace:name:music-store"
    }
  }
}
resource "nsxt_policy_group" "database_service" {
  display_name = "database-service"
  path         = "/infra/domains/default/groups/database-service"
  criteria {
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "service-name:database"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "app-name:music-store"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "env:prod"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "namespace:name:music-store"
    }
  }
}
resource "nsxt_policy_group" "music_store_app" {
  display_name = "music-store"
  path         = "/infra/domains/default/groups/music-store"
  criteria {
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "app-name:music-store"
    }
    condition {
      member_type = "SegmentPort"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "env:prod"
    }
  }
}
resource "nsxt_policy_group" "frontend" {
  display_name = "Music-store-frontend"
  path         = "/infra/domains/default/groups/Music-store-frontend"
}

# Security policy
resource "nsxt_policy_security_policy" "prod" {
  display_name = "prod"
  path         = "/infra/domains/default/security-policies/prod"
  category     = "Application"
  stateful     = true
  # Apply to specific container cluster (ANTREA)
  # NSX-T Policy path to the cluster control plane
  container_paths = [
    "/infra/sites/default/enforcement-points/default/cluster-control-planes/a9f2d700-30a3-4e5d-9fd9-622d15219d6b-e2e-ns-6j7x6-e2e-niran-cls01-antrea"
  ]
}

# Rules (use services)
resource "nsxt_policy_security_rule" "store_to_cart" {
  policy_path         = nsxt_policy_security_policy.prod.path
  display_name        = "store->cart"
  action              = "ALLOW"
  direction           = "IN"
  source_groups       = [nsxt_policy_group.store_service.path]
  destination_groups  = [nsxt_policy_group.cart_service.path]
  services            = [nsxt_policy_service.svc_tcp_5002.path]
}
resource "nsxt_policy_security_rule" "store_to_users" {
  policy_path         = nsxt_policy_security_policy.prod.path
  display_name        = "store->users"
  action              = "ALLOW"
  direction           = "IN"
  source_groups       = [nsxt_policy_group.store_service.path]
  destination_groups  = [nsxt_policy_group.users_service.path]
  services            = [nsxt_policy_service.svc_tcp_5003.path]
}
resource "nsxt_policy_security_rule" "store_to_db" {
  policy_path         = nsxt_policy_security_policy.prod.path
  display_name        = "store->database"
  action              = "ALLOW"
  direction           = "IN"
  source_groups       = [nsxt_policy_group.store_service.path]
  destination_groups  = [nsxt_policy_group.database_service.path]
  services            = [nsxt_policy_service.svc_tcp_5432.path]
}
resource "nsxt_policy_security_rule" "frontend_to_store" {
  policy_path         = nsxt_policy_security_policy.prod.path
  display_name        = "frontend"
  action              = "ALLOW"
  direction           = "IN"
  source_groups       = [nsxt_policy_group.frontend.path]
  destination_groups  = [nsxt_policy_group.music_store_app.path]
  services            = [nsxt_policy_service.svc_tcp_5000.path]
}
resource "nsxt_policy_security_rule" "cart_to_order" {
  policy_path         = nsxt_policy_security_policy.prod.path
  display_name        = "cart->order"
  action              = "ALLOW"
  direction           = "IN"
  source_groups       = [nsxt_policy_group.cart_service.path]
  destination_groups  = [nsxt_policy_group.order_service.path]
  services            = [nsxt_policy_service.svc_tcp_5001.path]
}
resource "nsxt_policy_security_rule" "store_to_order" {
  policy_path         = nsxt_policy_security_policy.prod.path
  display_name        = "store->order"
  action              = "ALLOW"
  direction           = "IN"
  source_groups       = [nsxt_policy_group.store_service.path]
  destination_groups  = [nsxt_policy_group.order_service.path]
  services            = [nsxt_policy_service.svc_tcp_5001.path]
}
resource "nsxt_policy_security_rule" "cleanup" {
  policy_path         = nsxt_policy_security_policy.prod.path
  display_name        = "cleanup"
  action              = "DROP"
  direction           = "IN"
  scope               = [nsxt_policy_group.music_store_app.path]
}


