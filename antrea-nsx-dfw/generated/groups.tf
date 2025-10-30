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
  }
}

resource "nsxt_policy_group" "cart_service" {
  display_name = "cart-service"
  path         = "/infra/domains/default/groups/cart-service"

  criteria {
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "service-name:cart" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "app-name:music-store" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "env:prod" }
  }
}

resource "nsxt_policy_group" "order_service" {
  display_name = "order-service"
  path         = "/infra/domains/default/groups/order-service"

  criteria {
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "service-name:order" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "app-name:music-store" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "env:prod" }
  }
}

resource "nsxt_policy_group" "users_service" {
  display_name = "users-service"
  path         = "/infra/domains/default/groups/users-service"

  criteria {
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "service-name:users" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "app-name:music-store" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "env:prod" }
  }
}

resource "nsxt_policy_group" "database_service" {
  display_name = "database-service"
  path         = "/infra/domains/default/groups/database-service"

  criteria {
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "service-name:database" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "app-name:music-store" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "env:prod" }
  }
}

resource "nsxt_policy_group" "music_store_app" {
  display_name = "music-store"
  path         = "/infra/domains/default/groups/music-store"

  criteria {
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "app-name:music-store" }
    condition { member_type = "SegmentPort" key = "Tag" operator = "EQUALS" value = "env:prod" }
  }
}

resource "nsxt_policy_group" "frontend" {
  display_name = "Music-store-frontend"
  path         = "/infra/domains/default/groups/Music-store-frontend"
  # External clients; leave criteria empty or customize per environment
}


