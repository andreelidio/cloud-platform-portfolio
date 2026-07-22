module "network" {
  source = "../../modules/network"

  name               = var.network_name
  cidr               = var.network_cidr
  availability_zones = var.availability_zones

  tags = local.common_tags

}