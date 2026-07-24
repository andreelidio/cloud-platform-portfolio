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

  vpc_id               = module.network.vpc_id
  private_subnet_ids   = values(module.network.private_subnet_ids)
    
  tags = local.common_tags
}