#!/usr/bin/env python3
"""
Script to create NSX-T DFW rules for Antrea using the NSX-T REST API.
The Terraform provider doesn't support Antrea group types, so we use the API directly.
"""

import requests
import json
import sys
import urllib3
from typing import Dict, List

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuration - update these values
NSXT_MANAGER = ""  # e.g., "nsxt-manager.example.com"
USERNAME = ""      # e.g., "admin"
PASSWORD = ""      # API password
CONTAINER_CLUSTER_ID = "a9f2d700-30a3-4e5d-9fd9-622d15219d6b-e2e-ns-6j7x6-e2e-niran-cls01-antrea"
NAMESPACE = "music-store"

# Service definitions
SERVICES = [
    {"name": "svc-tcp-5000", "port": 5000},
    {"name": "svc-tcp-5001", "port": 5001},
    {"name": "svc-tcp-5002", "port": 5002},
    {"name": "svc-tcp-5003", "port": 5003},
    {"name": "svc-tcp-5432", "port": 5432},
]

# Group definitions with Pod tags
GROUPS = [
    {
        "id": "store-service",
        "display_name": "store-service",
        "tags": [
            {"scope": "dis:k8s:app-name", "tag": "music-store"},
            {"scope": "dis:k8s:service-name", "tag": "store"},
            {"scope": "dis:k8s:env", "tag": "prod"},
        ],
    },
    {
        "id": "cart-service",
        "display_name": "cart-service",
        "tags": [
            {"scope": "dis:k8s:app-name", "tag": "music-store"},
            {"scope": "dis:k8s:service-name", "tag": "cart"},
            {"scope": "dis:k8s:env", "tag": "prod"},
        ],
    },
    {
        "id": "order-service",
        "display_name": "order-service",
        "tags": [
            {"scope": "dis:k8s:app-name", "tag": "music-store"},
            {"scope": "dis:k8s:service-name", "tag": "order"},
            {"scope": "dis:k8s:env", "tag": "prod"},
        ],
    },
    {
        "id": "users-service",
        "display_name": "users-service",
        "tags": [
            {"scope": "dis:k8s:app-name", "tag": "music-store"},
            {"scope": "dis:k8s:service-name", "tag": "users"},
            {"scope": "dis:k8s:env", "tag": "prod"},
        ],
    },
    {
        "id": "database-service",
        "display_name": "database-service",
        "tags": [
            {"scope": "dis:k8s:app-name", "tag": "music-store"},
            {"scope": "dis:k8s:service-name", "tag": "database"},
            {"scope": "dis:k8s:env", "tag": "prod"},
        ],
    },
    {
        "id": "music-store-app",
        "display_name": "music-store-app",
        "tags": [
            {"scope": "dis:k8s:app-name", "tag": "music-store"},
            {"scope": "dis:k8s:env", "tag": "prod"},
        ],
    },
]

# Security rules
RULES = [
    {
        "display_name": "store->cart",
        "source_groups": ["store-service"],
        "destination_groups": ["cart-service"],
        "services": ["svc-tcp-5002"],
        "action": "ALLOW",
    },
    {
        "display_name": "store->users",
        "source_groups": ["store-service"],
        "destination_groups": ["users-service"],
        "services": ["svc-tcp-5003"],
        "action": "ALLOW",
    },
    {
        "display_name": "store->database",
        "source_groups": ["store-service"],
        "destination_groups": ["database-service"],
        "services": ["svc-tcp-5432"],
        "action": "ALLOW",
    },
    {
        "display_name": "cart->order",
        "source_groups": ["cart-service"],
        "destination_groups": ["order-service"],
        "services": ["svc-tcp-5001"],
        "action": "ALLOW",
    },
    {
        "display_name": "store->order",
        "source_groups": ["store-service"],
        "destination_groups": ["order-service"],
        "services": ["svc-tcp-5001"],
        "action": "ALLOW",
    },
]


class NSXTClient:
    def __init__(self, manager: str, username: str, password: str):
        self.base_url = f"https://{manager}/policy/api/v1"
        self.auth = (username, password)
        self.headers = {"Content-Type": "application/json"}
        self.session = requests.Session()
        self.session.verify = False
        self.session.auth = self.auth

    def create_service(self, service_id: str, display_name: str, port: int) -> Dict:
        """Create a Layer 4 service definition"""
        url = f"{self.base_url}/infra/services/{service_id}"
        payload = {
            "display_name": display_name,
            "service_entries": [
                {
                    "id": f"{service_id}-entry",
                    "display_name": f"TCP {port}",
                    "resource_type": "L4PortSetServiceEntry",
                    "l4_protocol": "TCP",
                    "destination_ports": [str(port)],
                }
            ],
        }
        response = self.session.put(url, json=payload, headers=self.headers)
        if response.status_code in [200, 201]:
            print(f"✓ Created service: {display_name}")
            return response.json()
        else:
            print(f"✗ Failed to create service {display_name}: {response.text}")
            return None

    def create_antrea_group(
        self, group_id: str, display_name: str, tags: List[Dict], namespace: str
    ) -> Dict:
        """Create an Antrea-type group with Pod membership criteria"""
        url = f"{self.base_url}/infra/domains/default/groups/{group_id}"
        
        # Build membership criteria
        expressions = [
            {
                "resource_type": "Condition",
                "member_type": "Namespace",
                "key": "Name",
                "operator": "EQUALS",
                "value": namespace,
            }
        ]
        
        # Add Pod tag conditions
        for tag_spec in tags:
            expressions.append({
                "resource_type": "Condition",
                "member_type": "Pod",
                "key": "Tag",
                "operator": "EQUALS",
                "scope_operator": "EQUALS",
                "scope": tag_spec["scope"],
                "value": tag_spec["tag"],
            })
        
        payload = {
            "display_name": display_name,
            "expression": expressions,
        }
        
        response = self.session.patch(url, json=payload, headers=self.headers)
        if response.status_code in [200, 201]:
            print(f"✓ Created group: {display_name}")
            return response.json()
        else:
            print(f"✗ Failed to create group {display_name}: {response.text}")
            return None

    def create_security_policy(
        self,
        policy_id: str,
        display_name: str,
        rules: List[Dict],
        container_cluster_id: str,
        group_paths: Dict[str, str],
        service_paths: Dict[str, str],
    ) -> Dict:
        """Create a security policy with rules"""
        url = f"{self.base_url}/infra/domains/default/security-policies/{policy_id}"
        
        # Build rules
        policy_rules = []
        for idx, rule in enumerate(rules):
            source_paths = [group_paths[g] for g in rule["source_groups"]]
            dest_paths = [group_paths[g] for g in rule["destination_groups"]]
            service_paths_list = [service_paths[s] for s in rule.get("services", [])]
            
            rule_obj = {
                "display_name": rule["display_name"],
                "sequence_number": idx,
                "source_groups": source_paths,
                "destination_groups": dest_paths,
                "services": service_paths_list if service_paths_list else ["ANY"],
                "action": rule["action"],
                "direction": "IN_OUT",
                "logged": False,
            }
            policy_rules.append(rule_obj)
        
        # Container cluster scope
        cluster_path = f"/infra/sites/default/enforcement-points/default/container-clusters/{container_cluster_id}"
        
        payload = {
            "display_name": display_name,
            "category": "Environment",
            "stateful": True,
            "scope": [cluster_path],
            "rules": policy_rules,
        }
        
        response = self.session.patch(url, json=payload, headers=self.headers)
        if response.status_code in [200, 201]:
            print(f"✓ Created security policy: {display_name}")
            return response.json()
        else:
            print(f"✗ Failed to create security policy {display_name}: {response.text}")
            return None


def main():
    if not NSXT_MANAGER or not USERNAME or not PASSWORD:
        print("Error: Please update NSXT_MANAGER, USERNAME, and PASSWORD in the script")
        sys.exit(1)
    
    print(f"Connecting to NSX-T Manager: {NSXT_MANAGER}")
    client = NSXTClient(NSXT_MANAGER, USERNAME, PASSWORD)
    
    # Create services
    print("\n=== Creating Services ===")
    service_paths = {}
    for service in SERVICES:
        result = client.create_service(service["name"], service["name"], service["port"])
        if result:
            service_paths[service["name"]] = f"/infra/services/{service['name']}"
    
    # Create groups
    print("\n=== Creating Groups ===")
    group_paths = {}
    for group in GROUPS:
        result = client.create_antrea_group(
            group["id"], group["display_name"], group["tags"], NAMESPACE
        )
        if result:
            group_paths[group["id"]] = f"/infra/domains/default/groups/{group['id']}"
    
    # Create security policy
    print("\n=== Creating Security Policy ===")
    client.create_security_policy(
        "music-store-prod",
        "music-store-prod",
        RULES,
        CONTAINER_CLUSTER_ID,
        group_paths,
        service_paths,
    )
    
    print("\n✓ All resources created successfully!")
    print("\nNote: You may need to manually adjust the 'Applied To' scope in the NSX-T UI.")


if __name__ == "__main__":
    main()

