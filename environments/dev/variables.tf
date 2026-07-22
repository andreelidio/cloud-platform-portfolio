variable "aws_region" {
  type = string
}

variable "network_name" {
  type = string
}

variable "network_cidr" {
  type = string
}

variable "availability_zones" {
  type        = list(string)
  description = "Lista de zonas de disponibilidade usadas para criar sub-redes"
}
