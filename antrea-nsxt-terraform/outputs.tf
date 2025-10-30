output "security_policy_id" {
  description = "The ID of the created security policy"
  value       = nsxt_policy_security_policy.music_store_prod.id
}

output "security_policy_path" {
  description = "The path of the created security policy"
  value       = nsxt_policy_security_policy.music_store_prod.path
}

output "security_groups" {
  description = "Map of created security group names to their paths"
  value = {
    music-store-frontend = nsxt_policy_group.music_store_frontend.path
    store-service        = nsxt_policy_group.store_service.path
    cart-service         = nsxt_policy_group.cart_service.path
    order-service        = nsxt_policy_group.order_service.path
    users-service        = nsxt_policy_group.users_service.path
    database-service     = nsxt_policy_group.database_service.path
    music-store-all      = nsxt_policy_group.music_store_all.path
  }
}

output "custom_services" {
  description = "Map of created custom service names to their paths"
  value = {
    tcp-5000 = nsxt_policy_service.tcp_5000.path
    tcp-5001 = nsxt_policy_service.tcp_5001.path
    tcp-5002 = nsxt_policy_service.tcp_5002.path
    tcp-5003 = nsxt_policy_service.tcp_5003.path
    tcp-5432 = nsxt_policy_service.tcp_5432.path
  }
}

output "security_rules" {
  description = "Map of created security rule names to their IDs"
  value = {
    frontend        = nsxt_policy_security_policy_rule.frontend.id
    store-to-cart   = nsxt_policy_security_policy_rule.store_to_cart.id
    store-to-users  = nsxt_policy_security_policy_rule.store_to_users.id
    store-to-database = nsxt_policy_security_policy_rule.store_to_database.id
    store-to-order  = nsxt_policy_security_policy_rule.store_to_order.id
    cart-to-order   = nsxt_policy_security_policy_rule.cart_to_order.id
    cleanup         = nsxt_policy_security_policy_rule.cleanup.id
  }
}

output "cluster_id" {
  description = "The Antrea cluster control plane ID"
  value       = var.cluster_control_plane_id
}
