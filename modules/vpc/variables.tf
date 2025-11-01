variable "environment" {
  description = "The deployment environment name (e.g., dev, prd)."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "A list of availability zones to deploy into."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets (must match AZ count)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for private subnets (must match AZ count)."
  type        = list(string)
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateways for private subnet outbound access."
  type        = bool
  default     = true
}