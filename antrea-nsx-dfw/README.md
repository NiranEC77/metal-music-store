Antrea NSX-T DFW automation (CSV → Terraform)

Overview
- This folder converts your exported NSX-T Policy CSV (policies and rules) into Terraform HCL, generating:
  - Security policy (prod)
  - Security rules (store→cart/users/db/order, frontend→store, cleanup, malicious IP rules)
  - Placeholders for groups and services so you can fill them in or auto-generate them

Provider note
- The request references the VMware Cloud Foundation Terraform provider. See `vmware/terraform-provider-vcf` on GitHub for details: `https://github.com/vmware/terraform-provider-vcf`.
- NSX‑T Distributed Firewall (Policy API) is typically automated via the `vmware/nsxt` provider. This generator produces HCL for that Policy surface. You can still operate this under VCF governance if desired.

Usage
1) Place/update CSV in `csv/rules.csv` (already populated).
2) Generate HCL:
   ```bash
   cd antrea-nsx-dfw
   python3 scripts/generate_nsxt_hcl.py csv/rules.csv generated
   ```
3) Apply with Terraform:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

Files
- `csv/rules.csv` — your provided CSV export (policies and rules)
- `scripts/generate_nsxt_hcl.py` — converts CSV → HCL under `generated/`
  - outputs: `policies.tf`, `rules.tf`, `services.tf`, `groups.tf`, `providers.tf`, `variables.tf`
- `terraform/` — Terraform scaffold; it sources files from `generated/`

Fill-ins required
- Groups: Generated with label criteria; adjust to match your NSX tag scopes if needed.
- Services: Created for unique L4 ports seen in rules (TCP 5000/5001/5002/5003/5432).

Labels mapping and groups
- Uses labels `app-name`, `service-name`, `env` to build dynamic group criteria for Kubernetes SegmentPorts.
- Generated groups (paths from CSV):
  - `/infra/domains/default/groups/store-service` → `service-name=store` + `app-name=music-store` + `env=prod`
  - `/infra/domains/default/groups/cart-service` → `service-name=cart` + `app-name=music-store` + `env=prod`
  - `/infra/domains/default/groups/order-service` → `service-name=order` + `app-name=music-store` + `env=prod`
  - `/infra/domains/default/groups/users-service` → `service-name=users` + `app-name=music-store` + `env=prod`
  - `/infra/domains/default/groups/database-service` → `service-name=database` + `app-name=music-store` + `env=prod`
  - `/infra/domains/default/groups/music-store` → `app-name=music-store` + `env=prod`
  - `/infra/domains/default/groups/Music-store-frontend` → empty criteria (external client group; refine as needed)

Services
- Creates `nsxt_policy_service` resources for unique L4 ports found in rules: 5000, 5001, 5002, 5003, 5432 (TCP).


