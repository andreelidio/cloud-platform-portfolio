# NETWORK Variables
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "network_name" {
  description = "Name used as prefix for network resources"
  type        = string
}

variable "network_cidr" {
  description = "CIDR block assigned to the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones used to distribute network resources"
  type        = list(string)
}

# EKS Cluster Variables

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
}