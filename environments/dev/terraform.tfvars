# This file contains environment-specific variables for the dev environment.
aws_region = "us-east-1"

network_name = "platform-dev"

network_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

# EKS Cluster Variables
cluster_name       = "platform-dev-eks"
kubernetes_version = "1.33"

node_instance_types = ["t3.medium"]
node_capacity_type  = "ON_DEMAND"

node_desired_size = 2
node_min_size     = 2
node_max_size     = 3