locals {
  common_tags = merge(
    {
      Module    = "eks"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}