resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

