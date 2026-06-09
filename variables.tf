variable "aviatrix_controller_ip" {
  description = "Aviatrix Controller IP or hostname"
  type        = string
}

variable "aviatrix_username" {
  description = "Aviatrix Controller admin username"
  type        = string
  default     = "admin"
}

variable "aviatrix_password" {
  description = "Aviatrix Controller admin password"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "aws_account_name" {
  description = "Aviatrix onboarded AWS account name"
  type        = string
}

variable "transit_vpc_cidr" {
  description = "Transit VPC CIDR"
  type        = string
  default     = "10.10.0.0/23"
}

variable "spoke_vpc_cidr" {
  description = "Spoke VPC CIDR"
  type        = string
  default     = "10.20.0.0/23"
}

variable "transit_gw_size" {
  description = "Transit gateway instance size"
  type        = string
  default     = "c5.xlarge"
}

variable "spoke_gw_size" {
  description = "Spoke gateway instance size"
  type        = string
  default     = "t3.small"
}

variable "test_instance_key" {
  description = "SSH public key for test Ubuntu EC2"
  type        = string
}

variable "allweb_webgroup_uuid" {
  description = "UUID of the AllWeb webgroup for DCF policy"
  type        = string
  default     = "def000ad-0000-0000-0000-000000000002"
}

variable "anywhere_smartgroup_uuid" {
  description = "UUID of the Anywhere smart group (source: all)"
  type        = string
  default     = "def000ad-0000-0000-0000-000000000000"
}

variable "public_internet_smartgroup_uuid" {
  description = "UUID of the Public Internet smart group (destination)"
  type        = string
  default     = "def000ad-0000-0000-0000-000000000001"
}
