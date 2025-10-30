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


