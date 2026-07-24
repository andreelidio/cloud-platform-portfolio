variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to assign to EKS resources"
  type        = map(string)
  default     = {}
}

variable "node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group"
  type        = list(string)
}

variable "node_capacity_type" {
  description = "Capacity type used by the EKS managed node group"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition = contains(
      ["ON_DEMAND", "SPOT"],
      var.node_capacity_type
    )
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "endpoint_private_access" {
  description = "Enable private access to the EKS Kubernetes API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS Kubernetes API server endpoint"
  type        = bool
  default     = true
}

