module "network" {
  source = "../../modules/network"

  name               = var.network_name
  cidr               = var.network_cidr
  availability_zones = var.availability_zones

  tags = local.common_tags

}

module "eks" {
  source = "../../modules/eks"

  cluster_name         = var.cluster_name
  kubernetes_version   = var.kubernetes_version

  private_subnet_ids   = values(module.network.private_subnet_ids)
  public_access_cidrs    = var.eks_public_access_cidrs

  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type

  node_desired_size = var.node_desired_size
  node_min_size     = var.node_min_size
  node_max_size     = var.node_max_size
    
  tags = local.common_tags
}