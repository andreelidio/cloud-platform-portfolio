output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs by Availability Zone"

  value = {
    for az, subnet in aws_subnet.public :
    az => subnet.id
  }
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs by Availability Zone"

  value = {
    for az, subnet in aws_subnet.private :
    az => subnet.id
  }
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs by Availability Zone"

  value = {
    for az, nat in aws_nat_gateway.this :
    az => nat.id
  }
}

output "private_route_table_ids" {
  description = "Map of private route table IDs by Availability Zone"

  value = {
    for az, route_table in aws_route_table.private :
    az => route_table.id
  }
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}