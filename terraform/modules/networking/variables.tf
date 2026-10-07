variable "name" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 VPC CIDR. Subnets use /24 blocks."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition = (
      can(cidrnetmask(var.vpc_cidr)) &&
      can(regex("/16$", var.vpc_cidr))
    )
    error_message = "Provide a valid IPv4 /16 CIDR."
  }
}

variable "availability_zones" {
  description = "Two distinct availability zones."
  type        = list(string)

  validation {
    condition = (
      length(var.availability_zones) == 2 &&
      length(distinct(var.availability_zones)) == 2
    )
    error_message = "Provide exactly two distinct availability zones."
  }
}

variable "nat_gateway_count" {
  description = "One NAT for development; two for production."
  type        = number

  validation {
    condition     = contains([1, 2], var.nat_gateway_count)
    error_message = "NAT gateway count must be 1 or 2."
  }
}
