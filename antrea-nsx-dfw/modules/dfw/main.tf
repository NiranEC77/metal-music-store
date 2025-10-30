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
  l4_port_set_entry {
    display_name      = "TCP 5000"
    protocol          = "TCP"
    destination_ports = ["5000"]
  }
}
resource "nsxt_policy_service" "svc_tcp_5001" {
  display_name = "svc_tcp_5001"
  l4_port_set_entry {
    display_name      = "TCP 5001"
    protocol          = "TCP"
    destination_ports = ["5001"]
  }
}
resource "nsxt_policy_service" "svc_tcp_5002" {
  display_name = "svc_tcp_5002"
  l4_port_set_entry {
    display_name      = "TCP 5002"
    protocol          = "TCP"
    destination_ports = ["5002"]
  }
}
resource "nsxt_policy_service" "svc_tcp_5003" {
  display_name = "svc_tcp_5003"
  l4_port_set_entry {
    display_name      = "TCP 5003"
    protocol          = "TCP"
    destination_ports = ["5003"]
  }
}
resource "nsxt_policy_service" "svc_tcp_5432" {
  display_name = "svc_tcp_5432"
  l4_port_set_entry {
    display_name      = "TCP 5432"
    protocol          = "TCP"
    destination_ports = ["5432"]
  }
}

# Groups (label-based)
resource "nsxt_policy_group" "store_service" {
  display_name = "store-service"
  criteria {
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "service-name"
      value       = "store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "app-name"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "env"
      value       = "prod"
    }
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
  }
}
resource "nsxt_policy_group" "cart_service" {
  display_name = "cart-service"
  criteria {
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "service-name"
      value       = "cart"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "app-name"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "env"
      value       = "prod"
    }
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
  }
}
resource "nsxt_policy_group" "order_service" {
  display_name = "order-service"
  criteria {
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "service-name"
      value       = "order"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "app-name"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "env"
      value       = "prod"
    }
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
  }
}
resource "nsxt_policy_group" "users_service" {
  display_name = "users-service"
  criteria {
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "service-name"
      value       = "users"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "app-name"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "env"
      value       = "prod"
    }
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
  }
}
resource "nsxt_policy_group" "database_service" {
  display_name = "database-service"
  criteria {
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "service-name"
      value       = "database"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "app-name"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "env"
      value       = "prod"
    }
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
  }
}
resource "nsxt_policy_group" "music_store_app" {
  display_name = "music-store"
  criteria {
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "app-name"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      scope       = "env"
      value       = "prod"
    }
  }
}
resource "nsxt_policy_group" "frontend" {
  display_name = "Music-store-frontend"
}

# Security policy
resource "nsxt_policy_security_policy" "prod" {
  display_name = "prod"
  category     = "Application"
  stateful     = true

  rule {
    display_name        = "store->cart"
    action              = "ALLOW"
    direction           = "IN"
    source_groups       = [nsxt_policy_group.store_service.path]
    destination_groups  = []
    scope               = [nsxt_policy_group.cart_service.path]
    services            = [nsxt_policy_service.svc_tcp_5002.path]
  }
  rule {
    display_name        = "store->users"
    action              = "ALLOW"
    direction           = "IN"
    source_groups       = [nsxt_policy_group.store_service.path]
    destination_groups  = []
    scope               = [nsxt_policy_group.users_service.path]
    services            = [nsxt_policy_service.svc_tcp_5003.path]
  }
  rule {
    display_name        = "store->database"
    action              = "ALLOW"
    direction           = "IN"
    source_groups       = [nsxt_policy_group.store_service.path]
    destination_groups  = []
    scope               = [nsxt_policy_group.database_service.path]
    services            = [nsxt_policy_service.svc_tcp_5432.path]
  }
  rule {
    display_name        = "frontend"
    action              = "ALLOW"
    direction           = "IN"
    source_groups       = [nsxt_policy_group.frontend.path]
    destination_groups  = []
    scope               = [nsxt_policy_group.music_store_app.path]
    services            = [nsxt_policy_service.svc_tcp_5000.path]
  }
  rule {
    display_name        = "cart->order"
    action              = "ALLOW"
    direction           = "IN"
    source_groups       = [nsxt_policy_group.cart_service.path]
    destination_groups  = []
    scope               = [nsxt_policy_group.order_service.path]
    services            = [nsxt_policy_service.svc_tcp_5001.path]
  }
  rule {
    display_name        = "store->order"
    action              = "ALLOW"
    direction           = "IN"
    source_groups       = [nsxt_policy_group.store_service.path]
    destination_groups  = []
    scope               = [nsxt_policy_group.order_service.path]
    services            = [nsxt_policy_service.svc_tcp_5001.path]
  }
  rule {
    display_name        = "cleanup"
    action              = "DROP"
    direction           = "IN"
    scope               = [nsxt_policy_group.music_store_app.path]
  }
}


