# NSX-T DFW Rules for Antrea Music Store

This directory contains automation for creating NSX-T Distributed Firewall (DFW) rules for the Music Store application running on Kubernetes with Antrea CNI.

## Overview

The Terraform provider for NSX-T (`vmware/nsxt`) doesn't support creating "Antrea" type groups with Pod membership criteria. Therefore, we provide two approaches:

1. **Python Script (Recommended)**: Uses NSX-T REST API directly to create Antrea-compatible groups and policies
2. **Terraform**: Creates basic infrastructure but requires manual configuration in NSX-T UI

## Approach 1: Python Script (Using NSX-T API)

### Prerequisites

```bash
pip3 install requests urllib3
```

### Configuration

1. Edit `scripts/create_nsxt_antrea_dfw.py`
2. Update these variables:
   ```python
   NSXT_MANAGER = "your-nsxt-manager.example.com"
   USERNAME = "admin"
   PASSWORD = "your-password"
   ```

### Usage

```bash
cd /Users/niranevenchen/Documents/code/exmaple-music-store-1/antrea-nsx-dfw
python3 scripts/create_nsxt_antrea_dfw.py
```

### What It Creates

The script creates:

1. **Services** (TCP ports):
   - `svc-tcp-5000` - Store service (port 5000)
   - `svc-tcp-5001` - Order service (port 5001)
   - `svc-tcp-5002` - Cart service (port 5002)
   - `svc-tcp-5003` - Users service (port 5003)
   - `svc-tcp-5432` - Database service (port 5432)

2. **Groups** (Antrea type with Pod membership):
   - `store-service` - Matches pods with labels: `app-name=music-store`, `service-name=store`, `env=prod`
   - `cart-service` - Matches pods with labels: `app-name=music-store`, `service-name=cart`, `env=prod`
   - `order-service` - Matches pods with labels: `app-name=music-store`, `service-name=order`, `env=prod`
   - `users-service` - Matches pods with labels: `app-name=music-store`, `service-name=users`, `env=prod`
   - `database-service` - Matches pods with labels: `app-name=music-store`, `service-name=database`, `env=prod`
   - `music-store-app` - Matches all music-store pods with `env=prod`

3. **Security Policy** (`music-store-prod`):
   - Applied to container cluster: `a9f2d700-30a3-4e5d-9fd9-622d15219d6b-e2e-ns-6j7x6-e2e-niran-cls01-antrea`
   - Category: Environment (for Kubernetes/container workloads)
   - Rules:
     - `store->cart`: Allow store to communicate with cart on TCP 5002
     - `store->users`: Allow store to communicate with users on TCP 5003
     - `store->database`: Allow store to communicate with database on TCP 5432
     - `cart->order`: Allow cart to communicate with order on TCP 5001
     - `store->order`: Allow store to communicate with order on TCP 5001

## Approach 2: Terraform (Partial Automation)

### Prerequisites

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your NSX-T credentials
```

### Usage

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Limitations

- Terraform creates "Generic" type groups with SegmentPort membership (not Antrea type with Pod membership)
- Container cluster scope must be set manually in NSX-T UI after creation
- Groups may not automatically match pods - requires manual conversion to Antrea type

### Post-Terraform Manual Steps

1. In NSX-T UI, navigate to each created group
2. Change "Group Type" from "Generic" to "Antrea"
3. Update membership criteria to use "Pod" member type instead of "SegmentPort"
4. Verify tag scopes match: `dis:k8s:app-name`, `dis:k8s:service-name`, `dis:k8s:env`
5. For the security policy, set "Applied To" → "Antrea Container Clusters" → Select your cluster

## Source Data

The rules are defined in `csv/rules.csv` (exported from NSX-T).

## Pod Labels

Ensure your Kubernetes pods have these labels:
- `app-name: music-store`
- `service-name: <service>` (e.g., store, cart, order, users, database)
- `env: prod`

These are already configured in the k8s deployment YAML files in the parent directory.

## Troubleshooting

### Python Script Issues

- **Connection Error**: Verify NSX-T Manager hostname and network connectivity
- **Authentication Error**: Check username/password
- **API Errors**: Check NSX-T logs and verify the container cluster ID is correct

### Terraform Issues

- **Pod member type not supported**: This is expected - use the Python script instead
- **Invalid container cluster path**: The cluster scope must be set manually in UI

## Architecture

```
┌──────────┐         ┌──────────┐
│  Store   │────────▶│   Cart   │
│ (5000)   │         │  (5002)  │
└──────────┘         └──────────┘
     │                     │
     │                     ▼
     │               ┌──────────┐
     ├──────────────▶│  Order   │
     │               │  (5001)  │
     │               └──────────┘
     │
     ├──────────────▶┌──────────┐
     │               │  Users   │
     │               │  (5003)  │
     │               └──────────┘
     │
     └──────────────▶┌──────────┐
                     │ Database │
                     │  (5432)  │
                     └──────────┘
```

## Notes

- All policies use Category="Environment" for Kubernetes workloads
- Rules are stateful (bidirectional once connection is established)
- The namespace filter ensures rules only apply to pods in the `music-store` namespace
- Tag scopes use the `dis:k8s:` prefix which is the Antrea standard for Kubernetes labels
