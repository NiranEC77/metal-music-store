# Antrea NSX-T Terraform Automation

This Terraform configuration manages NSX-T distributed firewall (DFW) rules for the music store application with Antrea integration.

## Overview

This automation creates:
- **Security Groups**: Based on Kubernetes pod labels
- **Security Policy**: Antrea-integrated policy associated with the cluster
- **Security Rules**: Micro-segmentation rules controlling traffic between services

## Architecture

The configuration uses a modular structure:

```
antrea-nsxt-terraform/
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Variable definitions
├── terraform.tfvars.example         # Example variable values (copy to terraform.tfvars)
├── README.md                        # This file
└── modules/
    ├── security-groups/             # Security group module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security-policy/             # Security policy module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── security-rules/              # Security rules module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

1. **NSX-T Manager** with Antrea integration configured
2. **Terraform** >= 1.0
3. **Kubernetes cluster** with Antrea CNI
4. **Cluster Control Plane ID** from NSX-T

## Security Rules

The configuration creates the following micro-segmentation rules:

| Rule Name | Source | Destination | Port | Protocol | Action | Description |
|-----------|--------|-------------|------|----------|--------|-------------|
| frontend | ANY | Music-store-frontend | 5000 | TCP | ALLOW | External access to frontend |
| store->cart | store-service | cart-service | 5002 | TCP | ALLOW | Store to cart communication |
| store->users | store-service | users-service | 5003 | TCP | ALLOW | Store to users communication |
| store->database | store-service | database-service | 5432 | TCP | ALLOW | Store to database communication |
| store->order | store-service | order-service | 5001 | TCP | ALLOW | Store to order communication |
| cart->order | cart-service | order-service | 5001 | TCP | ALLOW | Cart to order communication |
| cleanup | ANY | ANY | ANY | ANY | DROP | Default deny for music-store |

## Security Groups

Security groups are created based on Kubernetes pod labels:

| Group Name | Label Match | Description |
|------------|-------------|-------------|
| Music-store-frontend | app=music-store-1 | Frontend service |
| store-service | service-name=store | Main store service |
| cart-service | service-name=cart | Shopping cart service |
| order-service | service-name=order | Order processing service |
| users-service | service-name=users | User management service |
| database-service | service-name=database | PostgreSQL database |
| music-store | app-name=music-store | All music store services |

## Setup Instructions

### 1. Copy Example Configuration

```bash
cd antrea-nsxt-terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Configuration

Edit `terraform.tfvars` with your environment details:

```hcl
nsx_manager = "your-nsx-manager.example.com"
nsx_username = "admin"
nsx_password = "your-secure-password"
cluster_control_plane_id = "your-cluster-id"
```

**Important**: The `cluster_control_plane_id` is your Antrea cluster ID. You provided:
```
a9f2d700-30a3-4e5d-9fd9-622d15219d6b-e2e-ns-6j7x6-e2e-niran-cls01-antrea
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Plan

```bash
terraform plan
```

### 5. Apply Configuration

```bash
terraform apply
```

## Configuration Variables

### Required Variables

- `nsx_manager`: NSX-T Manager hostname or IP
- `nsx_username`: NSX-T admin username
- `nsx_password`: NSX-T admin password (stored in terraform.tfvars, which is gitignored)
- `cluster_control_plane_id`: Antrea cluster control plane ID

### Optional Variables

- `allow_unverified_ssl`: Allow self-signed certificates (default: true)
- `domain`: NSX-T domain (default: "default")
- `policy_name`: Policy ID (default: "prod")
- `policy_display_name`: Policy display name (default: "music-store-prod")
- `policy_sequence_number`: Policy sequence (default: 499999)

## Kubernetes Label Requirements

Ensure your Kubernetes deployments have the appropriate labels for security group matching:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: music-store-1
spec:
  template:
    metadata:
      labels:
        app: music-store-1
        app-name: music-store
        service-name: store
        env: prod
```

## Security Considerations

1. **Passwords**: Never commit `terraform.tfvars` to git (it's gitignored)
2. **State Files**: Terraform state may contain sensitive data - use remote backends
3. **Least Privilege**: Rules follow zero-trust principles
4. **Default Deny**: The cleanup rule drops all traffic not explicitly allowed

## Terraform State Management

For production, use a remote backend:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state"
    key    = "antrea-nsxt/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Troubleshooting

### Check NSX-T Connection

```bash
terraform console
```

Then test:
```hcl
data.nsxt_policy_site.default
```

### Verify Cluster ID

Log into NSX-T Manager UI:
1. Navigate to Inventory → Container Clusters
2. Find your Antrea cluster
3. Verify the cluster ID matches your configuration

### Review Created Resources

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show nsxt_policy_security_policy.antrea_policy
```

## Maintenance

### Update Rules

1. Edit `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Add New Service

1. Add new security group to `security_groups` map
2. Add corresponding rules to `security_rules` list
3. Apply changes

### Destroy Resources

```bash
terraform destroy
```

**Warning**: This will remove all security policies and rules!

## References

- [NSX-T Terraform Provider Documentation](https://registry.terraform.io/providers/vmware/nsxt/latest/docs)
- [Antrea Documentation](https://antrea.io/docs/)
- [NSX-T Antrea Integration Guide](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html)

## Support

For issues or questions:
1. Review Terraform logs: `TF_LOG=DEBUG terraform apply`
2. Check NSX-T Manager logs
3. Verify Antrea integration status in NSX-T UI

