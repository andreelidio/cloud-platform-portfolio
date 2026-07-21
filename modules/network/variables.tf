variable "name" {
  description = "Network name"
  type        = string
}

variable "cidr" {

  description = "CIDR block"

  type = string

  validation {

    condition = can(cidrhost(var.cidr,0))

    error_message = "Invalid CIDR."

  }
}

variable "enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
