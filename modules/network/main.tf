#vpc
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

#internet gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

#subnets public
resource "aws_subnet" "public" {
  for_each = local.subnet_layout.public

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-public-${each.key}"
      Type = "public"
    }
  )
}

#route tables public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-public-rtb"
      Type = "public"
    }
  )
}

resource "aws_route_table_association" "this" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

#subnets private
resource "aws_subnet" "private" {
  for_each = local.subnet_layout.private

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-private-${each.key}"
      Type = "private"
    }
  )
}

#route tables private
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = merge(
    local.common_tags,
    {
      Name = aws_nat_gateway.this[each.key].id
      Type = "private"
    }
  )
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

#eip
resource "aws_eip" "nat" {
  for_each = aws_subnet.public

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-eip-${each.key}"
    }
  )
}

#nat gateway
resource "aws_nat_gateway" "this" {
  for_each = aws_subnet.public

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-gateway-${each.key}"
    }
  )
}