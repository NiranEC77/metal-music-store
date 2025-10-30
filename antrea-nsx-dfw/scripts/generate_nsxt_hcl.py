#!/usr/bin/env python3
import csv
import json
import os
import sys
from pathlib import Path


def ensure_dir(p: Path):
    p.mkdir(parents=True, exist_ok=True)


def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def parse_list_field(raw: str):
    if not raw:
        return []
    try:
        return json.loads(raw)
    except Exception:
        return []


def main(csv_path: str, out_dir: str):
    out = Path(out_dir)
    ensure_dir(out)

    policies = []
    rules = []

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)

    # Find headers and parse sections robustly
    i = 0
    while i < len(rows):
        row = rows[i]
        if not row:
            i += 1
            continue
        if row[0] == 'SecurityPolicyDto':
            # Next line is headers for policies
            if i + 1 < len(rows):
                pol_headers = rows[i + 1]
                j = i + 2
                while j < len(rows) and rows[j] and rows[j][0] not in ('RuleDto', 'SecurityPolicyContainerClusterDto', 'SecurityPolicyDto'):
                    policies.append(dict(zip(pol_headers, rows[j])))
                    j += 1
                i = j
                continue
        if row[0] == 'RuleDto':
            # Next line is headers for rules
            if i + 1 < len(rows):
                rule_headers = rows[i + 1]
                j = i + 2
                while j < len(rows) and rows[j] and rows[j][0] not in ('SecurityPolicyContainerClusterDto', 'SecurityPolicyDto', 'RuleDto'):
                    rules.append(dict(zip(rule_headers, rows[j])))
                    j += 1
                i = j
                continue
        i += 1

    # Minimal policy set: capture the prod policy line
    prod_policy = None
    for p in policies:
        path_val = p.get('path') or ''
        if path_val.strip().strip('"') == '/infra/domains/default/security-policies/prod':
            prod_policy = p
            break

    # Generate policies.tf
    policies_tf = []
    if prod_policy:
        policies_tf.append(
            'resource "nsxt_policy_security_policy" "prod" {\n'
            '  display_name = "prod"\n'
            '  path         = "/infra/domains/default/security-policies/prod"\n'
            '  category     = "Application"\n'
            '  stateful     = true\n'
            '}\n'
        )
    write_file(out / 'policies.tf', '\n'.join(policies_tf))

    # Generate rules.tf (convert subset; inline L4 services)
    rules_tf_lines = []
    rule_count = 0
    unique_ports = set()
    unique_groups = set()
    for r in rules:
        parent_path = ((r.get('parentPath') or '').strip().strip('"'))
        action = (r.get('action') or '').strip().upper()
        rule_id_num = r.get('ruleId') or '0'
        src_groups = parse_list_field(r.get('sourceGroups') or '')
        dst_groups = parse_list_field(r.get('destinationGroups') or '')
        service_entries = r.get('serviceEntries') or ''
        direction = (r.get('direction') or 'IN_OUT').strip()
        display_name = (r.get('displayName') or f"rule_{rule_id_num}")

        if 'security-policies/prod' not in parent_path:
            continue

        # try parse service entry list (inline L4 port definitions)
        ports = []
        try:
            entries = json.loads(service_entries.replace('""', '"')) if service_entries else []
            for e in entries:
                if e.get('l4_protocol') and e.get('destination_ports'):
                    for p in e['destination_ports']:
                        ports.append((e['l4_protocol'].upper(), p))
                        unique_ports.add((e['l4_protocol'].upper(), p))
        except Exception:
            pass

        rule_name = display_name.replace(' ', '_').replace('->', '_to_')
        rule_res = [
            f'resource "nsxt_policy_security_rule" "{rule_name}" {{',
            '  policy_path   = nsxt_policy_security_policy.prod.path',
            f'  display_name  = "{display_name}"',
            f'  action        = "{action.upper()}"',
            f'  direction     = "{direction}"',
        ]
        if src_groups:
            rule_res.append('  source_groups  = [')
            for g in src_groups:
                rule_res.append(f'    "{g}",')
                unique_groups.add(g)
            rule_res.append('  ]')
        if dst_groups:
            rule_res.append('  destination_groups  = [')
            for g in dst_groups:
                rule_res.append(f'    "{g}",')
                unique_groups.add(g)
            rule_res.append('  ]')
        if ports:
            rule_res.append('  services = []  # inline via service_entries below')
            for proto, port in ports:
                rule_res.append('  service_entry {')
                rule_res.append(f'    l4_protocol       = "{proto}"')
                rule_res.append('    source_ports      = []')
                rule_res.append(f'    destination_ports = ["{port}"]')
                rule_res.append('  }')

        rule_res.append('}')
        rules_tf_lines.append('\n'.join(rule_res))
        rule_count += 1

    write_file(out / 'rules.tf', '\n\n'.join(rules_tf_lines))

    # Generate services.tf for unique L4 ports
    services_tf_lines = []
    for proto, port in sorted(unique_ports, key=lambda x: (x[0], int(x[1]))):
        name = f"svc_{proto.lower()}_{port}"
        services_tf_lines.append('\n'.join([
            f'resource "nsxt_policy_service" "{name}" {{',
            f'  display_name = "{name}"',
            f'  service_entry {{',
            f'    display_name       = "{proto} {port}"',
            f'    l4_protocol        = "{proto}"',
            f'    destination_ports  = ["{port}"]',
            f'    resource_type      = "L4PortSetServiceEntry"',
            f'  }}',
            f'}}'
        ]))
    write_file(out / 'services.tf', '\n\n'.join(services_tf_lines))

    # Generate groups.tf based on referenced group paths and label mapping
    name_map = {
        'store-service':   {'service': 'store'},
        'cart-service':    {'service': 'cart'},
        'order-service':   {'service': 'order'},
        'users-service':   {'service': 'users'},
        'database-service':{'service': 'database'},
        'music-store':     {'app': 'music-store'},
        'Music-store-frontend': {'custom': 'frontend'},
    }

    def group_name_from_path(path: str) -> str:
        return path.strip('/').split('/')[-1]

    groups_tf_lines = []
    for gpath in sorted(unique_groups):
        gname = group_name_from_path(gpath)
        res_name = gname.replace('-', '_').lower()
        groups_tf_lines.append(f'resource "nsxt_policy_group" "{res_name}" {{')
        groups_tf_lines.append(f'  display_name = "{gname}"')
        groups_tf_lines.append(f'  path         = "{gpath}"')

        mapping = name_map.get(gname)
        if mapping and 'service' in mapping:
            svc = mapping['service']
            groups_tf_lines += [
                '  criteria {',
                '    condition {',
                '      member_type = "SegmentPort"',
                '      key         = "Tag"',
                '      operator    = "EQUALS"',
                f'      value       = "service-name:{svc}"',
                '    }',
                '    condition {',
                '      member_type = "SegmentPort"',
                '      key         = "Tag"',
                '      operator    = "EQUALS"',
                '      value       = "app-name:music-store"',
                '    }',
                '    condition {',
                '      member_type = "SegmentPort"',
                '      key         = "Tag"',
                '      operator    = "EQUALS"',
                '      value       = "env:prod"',
                '    }',
                '  }',
            ]
        elif mapping and 'app' in mapping:
            app = mapping['app']
            groups_tf_lines += [
                '  criteria {',
                '    condition {',
                '      member_type = "SegmentPort"',
                '      key         = "Tag"',
                '      operator    = "EQUALS"',
                f'      value       = "app-name:{app}"',
                '    }',
                '    condition {',
                '      member_type = "SegmentPort"',
                '      key         = "Tag"',
                '      operator    = "EQUALS"',
                '      value       = "env:prod"',
                '    }',
                '  }',
            ]
        else:
            # Leave empty criteria for external/frontend; user can refine
            pass

        groups_tf_lines.append('}')
        groups_tf_lines.append('')

    write_file(out / 'groups.tf', '\n'.join(groups_tf_lines))

    # providers and main
    providers_tf = (
        'terraform {\n'
        '  required_providers {\n'
        '    nsxt = {\n'
        '      source  = "vmware/nsxt"\n'
        '      version = ">= 3.4.0"\n'
        '    }\n'
        '  }\n'
        '}\n'
        '\n'
        'provider "nsxt" {\n'
        '  host                 = var.nsxt_host\n'
        '  username             = var.nsxt_username\n'
        '  password             = var.nsxt_password\n'
        '  allow_unverified_ssl = var.allow_unverified_ssl\n'
        '}\n'
    )
    write_file(out / 'providers.tf', providers_tf)

    variables_tf = (
        'variable "nsxt_host" { type = string }\n'
        'variable "nsxt_username" { type = string }\n'
        'variable "nsxt_password" { type = string, sensitive = true }\n'
        'variable "allow_unverified_ssl" { type = bool, default = true }\n'
    )
    write_file(out / 'variables.tf', variables_tf)

    main_tf = (
        '# Generated by generate_nsxt_hcl.py\n'
        'module "dfw" {\n'
        '  source = "../generated"\n'
        '}\n'
    )
    write_file(Path(csv_path).parent.parent / 'terraform' / 'main.tf', main_tf)

    print(f"Generated {rule_count} rule resources under {out}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: generate_nsxt_hcl.py <csv_path> <out_dir>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])


