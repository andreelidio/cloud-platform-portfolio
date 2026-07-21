locals {
  common_tags = merge(
    {
      Module    = "network"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}