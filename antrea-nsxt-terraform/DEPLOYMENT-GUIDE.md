# Antrea NSX-T Deployment Guide

## Quick Summary

This Terraform configuration creates NSX-T distributed firewall (DFW) rules integrated with your Antrea Kubernetes cluster to provide micro-segmentation for the music store application.

## ✅ What Was Created

### Directory Structure

```
antrea-nsxt-terraform/
├── main.tf                          # Main configuration
├── variables.tf                     # Variable definitions
├── outputs.tf                       # Output definitions
├── terraform.tfvars.example         # Example configuration
├── .terraform-version               # Terraform version lock
├── deploy.sh                        # Automated deployment script
├── README.md                        # Full documentation
├── DEPLOYMENT-GUIDE.md              # This file
└── modules/
    ├── security-groups/             # Creates NSX-T groups based on K8s labels
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security-policy/             # Creates security policy with Antrea binding
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── security-rules/              # Creates firewall rules
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔐 Security Architecture

### Traffic Flow with NSX-T DFW

```
                                     ┌─────────────────┐
                                     │   External      │
                                     │   Traffic       │
                                     └────────┬────────┘
                                              │
                                              │ Rule: frontend
                                              │ Port: 5000
                                              ▼
                          ┌─────────────────────────────────┐
                          │  Music Store Frontend           │
                          │  (store-service)                │
                          └──┬──────────┬──────────┬────────┘
                             │          │          │
                Rule:        │          │          │        Rule:
             store->cart     │          │          │     store->users
             Port: 5002      │          │          │     Port: 5003
                             │          │          │
                             ▼          │          ▼
                    ┌─────────────┐    │    ┌─────────────┐
                    │   Cart      │    │    │   Users     │
                    │   Service   │    │    │   Service   │
                    └──────┬──────┘    │    └─────────────┘
                           │           │
                Rule:      │           │ Rule:
             cart->order   │           │ store->order
             Port: 5001    │           │ Port: 5001
                           │           │
                           ▼           ▼
                       ┌──────────────────┐
                       │  Order Service   │
                       └──────────────────┘
                                │
                                │ Rule: store->database
                                │ Port: 5432
                                ▼
                       ┌──────────────────┐
                       │  PostgreSQL DB   │
                       └──────────────────┘
```

### Default Deny

All traffic to music-store services is **DENIED by default** via the cleanup rule. Only explicitly allowed traffic flows are permitted.

## 🏷️ Kubernetes Label Mapping

Your Kubernetes deployments already have the correct labels:

| Deployment | Labels | NSX-T Group |
|------------|--------|-------------|
| music-store-1 | `app=music-store-1`<br>`service-name=store` | Music-store-frontend<br>store-service |
| cart-service | `app=cart-service`<br>`service-name=cart` | cart-service |
| order-service | `app=order-service`<br>`service-name=order` | order-service |
| users-service | `app=users-service`<br>`service-name=users` | users-service |
| postgres | `app=postgres`<br>`service-name=database` | database-service |

All services have: `app-name=music-store` and `env=prod`

## 📋 Pre-Deployment Checklist

- [ ] NSX-T Manager is accessible
- [ ] You have admin credentials for NSX-T
- [ ] Antrea is deployed and integrated with NSX-T
- [ ] Cluster control plane ID is available
- [ ] Terraform is installed (v1.0+)
- [ ] Kubernetes deployments have correct labels

## 🚀 Deployment Steps

### Option 1: Using the Deploy Script (Recommended)

```bash
cd antrea-nsxt-terraform
./deploy.sh
```

The script will:
1. Check prerequisites
2. Create `terraform.tfvars` from example
3. Prompt you to configure credentials
4. Initialize Terraform
5. Validate configuration
6. Show plan for review
7. Apply configuration

### Option 2: Manual Deployment

```bash
cd antrea-nsxt-terraform

# 1. Create configuration
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars
# Update these values:
# - nsx_manager = "your-nsx-manager.example.com"
# - nsx_username = "admin"
# - nsx_password = "your-password"
# - cluster_control_plane_id = "a9f2d700-30a3-4e5d-9fd9-622d15219d6b-e2e-ns-6j7x6-e2e-niran-cls01-antrea"

# 3. Initialize
terraform init

# 4. Plan
terraform plan

# 5. Apply
terraform apply
```

## 🔍 Verification

### 1. Check Terraform Outputs

```bash
terraform output
```

Expected output:
```hcl
cluster_id = "a9f2d700-30a3-4e5d-9fd9-622d15219d6b-e2e-ns-6j7x6-e2e-niran-cls01-antrea"
security_groups = {
  "cart-service" = "/infra/domains/default/groups/cart-service"
  "database-service" = "/infra/domains/default/groups/database-service"
  # ... more groups
}
security_policy_id = "prod"
security_policy_path = "/infra/domains/default/security-policies/prod"
security_rules = {
  "cart->order" = "/infra/domains/default/security-policies/prod/rules/cart->order"
  # ... more rules
}
```

### 2. Check NSX-T Manager UI

1. Log into NSX-T Manager
2. Navigate to **Security** → **Distributed Firewall**
3. Look for policy: **"music-store-prod"**
4. Verify 7 rules are present:
   - frontend (ALLOW)
   - store->cart (ALLOW)
   - store->users (ALLOW)
   - store->database (ALLOW)
   - store->order (ALLOW)
   - cart->order (ALLOW)
   - cleanup (DROP)

### 3. Check Security Groups

1. Navigate to **Inventory** → **Groups**
2. Verify these groups exist:
   - Music-store-frontend
   - store-service
   - cart-service
   - order-service
   - users-service
   - database-service
   - music-store

### 4. Verify Cluster Association

1. Navigate to **Inventory** → **Container Clusters**
2. Find your cluster: `a9f2d700-30a3-4e5d-9fd9-622d15219d6b-e2e-ns-6j7x6-e2e-niran-cls01-antrea`
3. Check that the security policy is associated

## 🧪 Testing Traffic Rules

### Test 1: Frontend Access (Should Work)

```bash
# From outside the cluster
curl http://<loadbalancer-ip>:5000
```

Expected: HTTP 200 response from music store frontend

### Test 2: Direct Cart Access (Should Fail)

```bash
# Try to access cart service directly from outside
curl http://<cart-service-ip>:5002
```

Expected: Connection timeout/refused (no rule allows external access)

### Test 3: Internal Service Communication

Deploy a test pod:

```bash
kubectl run test-pod --rm -it --image=curlimages/curl -- sh

# From inside the cluster, test allowed communication
# This should work (store->cart rule allows it)
curl http://cart-service:5002

# This should timeout (no rule allows pod->cart without proper labels)
```

### Test 4: Database Access Restrictions

```bash
# Only store-service should access database
# Deploy a test pod and try to connect to postgres
kubectl run test-pod --rm -it --image=postgres:14 -- sh
psql -h postgres-service -U music_user -d music_store
```

Expected: Connection should fail unless pod has `service-name=store` label

## 🔧 Troubleshooting

### Issue: Rules Not Applied

**Check:**
1. Antrea integration status in NSX-T
2. Cluster control plane ID is correct
3. Security policy is associated with cluster

**Fix:**
```bash
# Re-apply policy association
terraform taint 'module.security_policy.nsxt_policy_predefined_security_policy.cluster_binding[0]'
terraform apply
```

### Issue: Traffic Blocked Unexpectedly

**Debug:**
1. Check NSX-T DFW logs
2. Verify pod labels match security group criteria
3. Check rule sequence numbers (lower = higher priority)

```bash
# View pod labels
kubectl get pods --show-labels

# Add missing labels
kubectl label pod <pod-name> service-name=store
```

### Issue: Cannot Connect to NSX-T Manager

**Check:**
```bash
# Test connectivity
ping <nsx-manager>

# Verify credentials
curl -k -u admin:password https://<nsx-manager>/api/v1/cluster
```

## 📊 Monitoring and Logging

### Enable Rule Logging

Edit `terraform.tfvars` and set `logged = true` for specific rules:

```hcl
security_rules = [
  {
    display_name = "frontend"
    # ... other settings
    logged = true  # Enable logging
  }
]
```

Then apply:
```bash
terraform apply
```

### View Logs in NSX-T

1. **GUI**: Security → Distributed Firewall → Select rule → View logs
2. **CLI**: SSH to NSX Manager and check logs

## 🔄 Making Changes

### Add a New Service

1. **Update Kubernetes deployment** with labels:
```yaml
labels:
  app-name: music-store
  service-name: new-service
  env: prod
```

2. **Add security group** to `terraform.tfvars`:
```hcl
security_groups = {
  # ... existing groups
  "new-service" = {
    display_name = "new-service"
    description  = "New service description"
    criteria = [{
      member_type = "VirtualMachine"
      key         = "service-name"
      operator    = "EQUALS"
      value       = "new-service"
    }]
  }
}
```

3. **Add rules** for new service:
```hcl
security_rules = [
  # ... existing rules
  {
    display_name       = "store->new-service"
    description        = "Allow store to access new service"
    action             = "ALLOW"
    sequence_number    = 50000
    source_groups      = ["store-service"]
    destination_groups = ["new-service"]
    services           = []
    destination_ports  = ["8080"]
    protocol           = "TCP"
    scope_groups       = ["new-service"]
    direction          = "IN"
    logged             = false
    disabled           = false
  }
]
```

4. **Apply changes**:
```bash
terraform apply
```

### Modify Existing Rule

Edit the rule in `terraform.tfvars` and run:
```bash
terraform plan  # Review changes
terraform apply # Apply changes
```

### Remove Rules/Groups

Comment out or remove from `terraform.tfvars`, then:
```bash
terraform apply
```

## 🗑️ Cleanup

To remove all NSX-T resources:

```bash
terraform destroy
```

**Warning**: This will remove all security policies and rules!

## 📚 Additional Resources

- [NSX-T Terraform Provider Documentation](https://registry.terraform.io/providers/vmware/nsxt/latest/docs)
- [Antrea Documentation](https://antrea.io/docs/)
- [NSX-T DFW Best Practices](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html)

## 🆘 Support

For issues:
1. Check Terraform logs: `TF_LOG=DEBUG terraform apply 2>&1 | tee terraform.log`
2. Check NSX-T Manager logs
3. Verify Antrea integration status
4. Review this guide and README.md

## 🎯 Next Steps

After successful deployment:

1. ✅ Monitor NSX-T DFW logs for denied traffic
2. ✅ Fine-tune rules based on application behavior
3. ✅ Enable logging on critical rules
4. ✅ Document any custom changes
5. ✅ Set up Terraform remote backend for state management
6. ✅ Implement CI/CD for automated policy updates

