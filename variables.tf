locals {
  subnets = length(data.aws_availability_zones.available.names)
}

variable "enable_nat_gateway" {
  type = bool
  default = false
}

variable "project" {
  default = "demo"
}
variable "environment" {}
variable "sanjosnet" {}
