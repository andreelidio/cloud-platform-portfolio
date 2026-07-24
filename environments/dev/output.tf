output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs by Availability Zone"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs by Availability Zone"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs by Availability Zone"
  value       = module.network.nat_gateway_ids
}