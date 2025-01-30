variable "vpc_cidr_block" {
    type        = string
    description = "VPC cidr block"
    default     = "10.10.1.0/24"
}

variable "vpc_net_host_bits" {
    type = number
    description = "Number of bits used for network host addressing"
    default = 3
}

variable "ad_password" {
  description = "Administrative password for Acive Directory"
  type        = string
  sensitive   = true
}