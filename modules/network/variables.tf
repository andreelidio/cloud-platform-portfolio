variable "name" {
  description = "Network name"
  type        = string
}

variable "cidr" {
  description = "CIDR block assigned to the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "Invalid CIDR."
  }
}

variable "enable_dns_support" {
  description = "Enable or disable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable or disable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to assign to network resources"
  type        = map(string)
  default     = {}
}

variable "availability_zones" {
  description = "List of Availability Zones used to distribute network resources"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}