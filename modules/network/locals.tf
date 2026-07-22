locals {

  common_tags = merge(
    {
      Module    = "network"
      ManagedBy = "Terraform"
    },
    var.tags
  )

  subnet_layout = {

    public = {
      for index, az in var.availability_zones :
      az => {
        cidr = cidrsubnet(var.cidr, 4, index)
      }
    }

    private = {
      for index, az in var.availability_zones :
      az => {
        cidr = cidrsubnet(
          var.cidr,
          4,
          index + length(var.availability_zones)
        )
      }
    }

  }

}