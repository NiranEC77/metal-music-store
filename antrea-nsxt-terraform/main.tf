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

#############################################
# Custom Services - Port Definitions
#############################################

resource "nsxt_policy_service" "tcp_5000" {
  display_name = "tcp-5000"
  description  = "HTTP port 5000"
  
  l4_port_set_entry {
    display_name      = "tcp-5000"
    protocol          = "TCP"
    destination_ports = ["5000"]
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_service" "tcp_5001" {
  display_name = "tcp-5001"
  description  = "Order service port 5001"
  
  l4_port_set_entry {
    display_name      = "tcp-5001"
    protocol          = "TCP"
    destination_ports = ["5001"]
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_service" "tcp_5002" {
  display_name = "tcp-5002"
  description  = "Cart service port 5002"
  
  l4_port_set_entry {
    display_name      = "tcp-5002"
    protocol          = "TCP"
    destination_ports = ["5002"]
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_service" "tcp_5003" {
  display_name = "tcp-5003"
  description  = "Users service port 5003"
  
  l4_port_set_entry {
    display_name      = "tcp-5003"
    protocol          = "TCP"
    destination_ports = ["5003"]
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_service" "tcp_5432" {
  display_name = "tcp-5432"
  description  = "PostgreSQL port 5432"
  
  l4_port_set_entry {
    display_name      = "tcp-5432"
    protocol          = "TCP"
    destination_ports = ["5432"]
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

#############################################
# Security Groups - Based on K8s Labels
#############################################

resource "nsxt_policy_group" "music_store_frontend" {
  display_name = "Music-store-frontend"
  description  = "Music store frontend service"
  domain       = "default"

  criteria {
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app-name|music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:env|prod"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app|music-store-1"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_group" "store_service" {
  display_name = "store-service"
  description  = "Music store main service"
  domain       = "default"

  criteria {
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app-name|music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:env|prod"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:service-name|store"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_group" "cart_service" {
  display_name = "cart-service"
  description  = "Shopping cart service"
  domain       = "default"

  criteria {
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app-name|music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:env|prod"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:service-name|cart"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_group" "order_service" {
  display_name = "order-service"
  description  = "Order processing service"
  domain       = "default"

  criteria {
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app-name|music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:env|prod"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:service-name|order"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_group" "users_service" {
  display_name = "users-service"
  description  = "User management service"
  domain       = "default"

  criteria {
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app-name|music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:env|prod"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:service-name|users"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_group" "database_service" {
  display_name = "database-service"
  description  = "PostgreSQL database service"
  domain       = "default"

  criteria {
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app-name|music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:env|prod"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:service-name|database"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

resource "nsxt_policy_group" "music_store_all" {
  display_name = "music-store-all"
  description  = "All music store services"
  domain       = "default"

  criteria {
    condition {
      member_type = "Namespace"
      key         = "Name"
      operator    = "EQUALS"
      value       = "music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:app-name|music-store"
    }
    condition {
      member_type = "Pod"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "dis:k8s:env|prod"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}

#############################################
# Security Policy
#############################################

resource "nsxt_policy_security_policy" "music_store_prod" {
  display_name    = "tf-music-store-prod"
  description     = "Antrea-integrated security policy for music store production"
  category        = "Application"
  domain          = "default"
  sequence_number = 499999
  stateful        = true
  tcp_strict      = true

  # Scope omitted = applies to ANY (cluster association handled by Antrea)
  # Note: The cluster control plane association is managed automatically by Antrea
  # when resources have matching labels/tags

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  tag {
    scope = "environment"
    tag   = "production"
  }

  tag {
    scope = "cluster"
    tag   = var.cluster_control_plane_id
  }
}

#############################################
# Security Rules
#############################################

# Rule 1: Allow external access to frontend
resource "nsxt_policy_security_policy_rule" "frontend" {
  display_name       = "frontend"
  description        = "Allow external access to frontend"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 249999
  action             = "ALLOW"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  # source_groups omitted = ANY
  # destination_groups omitted for Antrea - use scope (applied to) instead
  services           = [nsxt_policy_service.tcp_5000.path]
  scope              = [nsxt_policy_group.music_store_frontend.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.music_store_frontend]
}

# Rule 2: Store -> Cart
resource "nsxt_policy_security_policy_rule" "store_to_cart" {
  display_name       = "store->cart"
  description        = "Allow store service to access cart service"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 124999
  action             = "ALLOW"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  source_groups      = [nsxt_policy_group.store_service.path]
  # destination_groups omitted for Antrea - use scope (applied to) instead
  services           = [nsxt_policy_service.tcp_5002.path]
  scope              = [nsxt_policy_group.cart_service.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.store_service, nsxt_policy_group.cart_service]
}

# Rule 3: Store -> Users
resource "nsxt_policy_security_policy_rule" "store_to_users" {
  display_name       = "store->users"
  description        = "Allow store service to access users service"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 31249
  action             = "ALLOW"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  source_groups      = [nsxt_policy_group.store_service.path]
  # destination_groups omitted for Antrea - use scope (applied to) instead
  services           = [nsxt_policy_service.tcp_5003.path]
  scope              = [nsxt_policy_group.users_service.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.store_service, nsxt_policy_group.users_service]
}

# Rule 4: Store -> Database
resource "nsxt_policy_security_policy_rule" "store_to_database" {
  display_name       = "store->database"
  description        = "Allow store service to access database"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 15624
  action             = "ALLOW"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  source_groups      = [nsxt_policy_group.store_service.path]
  # destination_groups omitted for Antrea - use scope (applied to) instead
  services           = [nsxt_policy_service.tcp_5432.path]
  scope              = [nsxt_policy_group.database_service.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.store_service, nsxt_policy_group.database_service]
}

# Rule 5: Store -> Order
resource "nsxt_policy_security_policy_rule" "store_to_order" {
  display_name       = "store->order"
  description        = "Allow store service to access order service"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 62499
  action             = "ALLOW"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  source_groups      = [nsxt_policy_group.store_service.path]
  # destination_groups omitted for Antrea - use scope (applied to) instead
  services           = [nsxt_policy_service.tcp_5001.path]
  scope              = [nsxt_policy_group.order_service.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.store_service, nsxt_policy_group.order_service]
}

# Rule 6: Cart -> Order
resource "nsxt_policy_security_policy_rule" "cart_to_order" {
  display_name       = "cart->order"
  description        = "Allow cart service to access order service"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 7812
  action             = "ALLOW"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  source_groups      = [nsxt_policy_group.cart_service.path]
  # destination_groups omitted for Antrea - use scope (applied to) instead
  services           = [nsxt_policy_service.tcp_5001.path]
  scope              = [nsxt_policy_group.order_service.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.cart_service, nsxt_policy_group.order_service]
}

# Rule 7: Cleanup (Default Deny)
resource "nsxt_policy_security_policy_rule" "cleanup" {
  display_name       = "cleanup"
  description        = "Drop all other traffic to music store"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 499999
  action             = "DROP"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  # All omitted = ANY for source, destination, and services
  scope              = [nsxt_policy_group.music_store_all.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.music_store_all]
}
