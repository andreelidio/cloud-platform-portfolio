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

variable "node_instance_types" {
  description = "EC2 instance types used by EKS worker nodes"
  type        = list(string)
}

variable "node_capacity_type" {
  description = "Capacity type used by EKS worker nodes"
  type        = string
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
}

variable "eks_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the EKS cluster API server"
  type        = list(string)
}