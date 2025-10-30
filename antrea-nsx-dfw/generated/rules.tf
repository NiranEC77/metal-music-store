resource "nsxt_policy_security_rule" "store_to_cart" {
  policy_path     = nsxt_policy_security_policy.prod.path
  display_name    = "store->cart"
  action          = "ALLOW"
  direction       = "IN"
  source_groups   = ["/infra/domains/default/groups/store-service"]
  destination_groups = ["/infra/domains/default/groups/cart-service"]
  service_entry {
    l4_protocol       = "TCP"
    source_ports      = []
    destination_ports = ["5002"]
  }
}

resource "nsxt_policy_security_rule" "store_to_users" {
  policy_path     = nsxt_policy_security_policy.prod.path
  display_name    = "store->users"
  action          = "ALLOW"
  direction       = "IN"
  source_groups   = ["/infra/domains/default/groups/store-service"]
  destination_groups = ["/infra/domains/default/groups/users-service"]
  service_entry { l4_protocol = "TCP" source_ports = [] destination_ports = ["5003"] }
}

resource "nsxt_policy_security_rule" "store_to_db" {
  policy_path     = nsxt_policy_security_policy.prod.path
  display_name    = "store->database"
  action          = "ALLOW"
  direction       = "IN"
  source_groups   = ["/infra/domains/default/groups/store-service"]
  destination_groups = ["/infra/domains/default/groups/database-service"]
  service_entry { l4_protocol = "TCP" source_ports = [] destination_ports = ["5432"] }
}

resource "nsxt_policy_security_rule" "frontend_to_store" {
  policy_path     = nsxt_policy_security_policy.prod.path
  display_name    = "frontend"
  action          = "ALLOW"
  direction       = "IN"
  source_groups   = ["/infra/domains/default/groups/Music-store-frontend"]
  destination_groups = ["/infra/domains/default/groups/music-store"]
  service_entry { l4_protocol = "TCP" source_ports = [] destination_ports = ["5000"] }
}

resource "nsxt_policy_security_rule" "cart_to_order" {
  policy_path     = nsxt_policy_security_policy.prod.path
  display_name    = "cart->order"
  action          = "ALLOW"
  direction       = "IN"
  source_groups   = ["/infra/domains/default/groups/cart-service"]
  destination_groups = ["/infra/domains/default/groups/order-service"]
  service_entry { l4_protocol = "TCP" source_ports = [] destination_ports = ["5001"] }
}

resource "nsxt_policy_security_rule" "store_to_order" {
  policy_path     = nsxt_policy_security_policy.prod.path
  display_name    = "store->order"
  action          = "ALLOW"
  direction       = "IN"
  source_groups   = ["/infra/domains/default/groups/store-service"]
  destination_groups = ["/infra/domains/default/groups/order-service"]
  service_entry { l4_protocol = "TCP" source_ports = [] destination_ports = ["5001"] }
}

resource "nsxt_policy_security_rule" "cleanup" {
  policy_path     = nsxt_policy_security_policy.prod.path
  display_name    = "cleanup"
  action          = "DROP"
  direction       = "IN"
  scope           = ["/infra/domains/default/groups/music-store"]
}


