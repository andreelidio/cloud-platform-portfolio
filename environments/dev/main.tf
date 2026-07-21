module "network" {

  source = "../../modules/network"

  name = var.network_name

  cidr = var.network_cidr

  tags = local.common_tags

}