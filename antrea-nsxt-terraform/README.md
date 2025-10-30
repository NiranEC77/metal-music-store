# Antrea NSX-T Terraform Configuration

Simple Terraform configuration to manage NSX-T distributed firewall (DFW) rules for the music store application with Antrea integration.

## Structure

```
antrea-nsxt-terraform/
├── main.tf                      # All resources defined here
├── variables.tf                 # Connection variables only
├── outputs.tf                   # Output definitions
├── terraform.tfvars.example     # Example connection config
└── README.md                    # This file
```

## What Gets Created

### Services (5)
- `tcp-5000` - Frontend HTTP
- `tcp-5001` - Order service
- `tcp-5002` - Cart service
- `tcp-5003` - Users service
- `tcp-5432` - PostgreSQL

### Security Groups (7)
Based on Kubernetes pod labels:
- `Music-store-frontend` - Tag: `app|music-store-1`
- `store-service` - Tag: `service-name|store`
- `cart-service` - Tag: `service-name|cart`
- `order-service` - Tag: `service-name|order`
- `users-service` - Tag: `service-name|users`
- `database-service` - Tag: `service-name|database`
- `music-store` - Tag: `app-name|music-store` (all services)

### Security Policy (1)
- `music-store-prod` - Application category, sequence 499999
- Scoped to Antrea cluster control plane

### Security Rules (7)
1. **frontend** (249999) - ANY → frontend:5000 ✅ ALLOW
2. **store→cart** (124999) - store → cart:5002 ✅ ALLOW
3. **store→users** (31249) - store → users:5003 ✅ ALLOW
4. **store→database** (15624) - store → db:5432 ✅ ALLOW
5. **store→order** (62499) - store → order:5001 ✅ ALLOW
6. **cart→order** (7812) - cart → order:5001 ✅ ALLOW
7. **cleanup** (499999) - ANY → ANY (music-store scope) ❌ DROP

## Quick Start

### 1. Configure Connection

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Edit with your NSX-T details:
```hcl
nsx_manager              = "your-nsx-manager.example.com"
nsx_username             = "admin"
nsx_password             = "your-password"
cluster_control_plane_id = "your-antrea-cluster-id"
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Verify

```bash
terraform output
```

## Modifying Rules

All configuration is in `main.tf`. To modify:

### Add a New Service

```hcl
resource "nsxt_policy_service" "tcp_8080" {
  display_name = "tcp-8080"
  description  = "Custom service on 8080"
  
  l4_port_set_entry {
    display_name      = "tcp-8080"
    protocol          = "TCP"
    destination_ports = ["8080"]
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}
```

### Add a New Security Group

```hcl
resource "nsxt_policy_group" "new_service" {
  display_name = "new-service"
  description  = "New service group"
  domain       = "default"

  criteria {
    condition {
      member_type = "VirtualMachine"
      key         = "Tag"
      operator    = "EQUALS"
      value       = "service-name|new-service"
    }
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }
}
```

### Add a New Rule

```hcl
resource "nsxt_policy_security_policy_rule" "new_rule" {
  display_name       = "store->new-service"
  description        = "Allow store to access new service"
  policy_path        = nsxt_policy_security_policy.music_store_prod.path
  sequence_number    = 50000
  action             = "ALLOW"
  direction          = "IN"
  ip_version         = "IPV4_IPV6"
  logged             = false
  disabled           = false

  source_groups      = [nsxt_policy_group.store_service.path]
  destination_groups = [nsxt_policy_group.new_service.path]
  services           = [nsxt_policy_service.tcp_8080.path]
  scope              = [nsxt_policy_group.new_service.path]

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  depends_on = [nsxt_policy_group.store_service, nsxt_policy_group.new_service]
}
```

Then apply:
```bash
terraform apply
```

## Kubernetes Label Requirements

Ensure your deployments have the correct labels:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: music-store-1
spec:
  template:
    metadata:
      labels:
        app: music-store-1           # For frontend group
        app-name: music-store         # For music-store-all group
        service-name: store           # For store-service group
        env: prod
```

## Troubleshooting

### Check Resources

```bash
terraform state list
terraform state show nsxt_policy_security_policy.music_store_prod
```

### Enable Rule Logging

In `main.tf`, change `logged = false` to `logged = true` for any rule:

```hcl
resource "nsxt_policy_security_policy_rule" "frontend" {
  # ... other config
  logged = true  # Enable logging
}
```

Then apply:
```bash
terraform apply
```

### Verify in NSX-T UI

1. Log into NSX-T Manager
2. Navigate to **Security** → **Distributed Firewall**
3. Look for policy: **music-store-prod**
4. Verify all 7 rules are present

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Warning**: This will remove all security policies and rules!

## References

- [NSX-T Terraform Provider](https://registry.terraform.io/providers/vmware/nsxt/latest/docs)
- [Antrea Documentation](https://antrea.io/docs/)
