variable "cluster_name" {
  type        = string
  default     = "inception-eks-managed-ng"
  description = "Cluster name"
}

variable "region" {
  type        = string
  default     = "ap-southeast-1"
  description = "Region"
}

variable "ami_type" {
  type        = string
  default     = "AL2_x86_64"
  description = "AMI Type"
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.small"]
  description = "Instance types"
}

variable "capacity_type" {
  type        = string
  default     = "SPOT"
  description = "Capacity type"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  description = "Private Subnets"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  description = "Public Subnets"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum Number of Nodes"
}

variable "max_size" {
  type        = number
  default     = 4
  description = "Maximum Number of Nodes"
}

variable "desired_size" {
  type        = number
  default     = 3
  description = "Desired Number of Nodes"
}

variable "disk_size" {
  type        = number
  default     = 50
  description = "Disk Size"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = false
  description = "Provide public access to Cluster Endpoint"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  default     = true
  description = "Provide private access to Cluster Endpoint"
}

variable "eks_read_only_role_creation" {
  description = "Creates a read only iam and rbac role"
  type        = bool
  default     = "false"
}

variable "eks_read_write_role_creation" {
  description = "Creates a eks read write iam role"
  type        = bool
  default     = "false"
}

variable "iam_account_id" {
  type        = string
  default     = ""
  description = "Account ID where IAM group is created"
}

variable "eks_version" {
  type    = string
  default = "1.23"
}

variable "number_of_azs" {
  description = "Number of Availability Zones"
  type        = number
  default     = 3
}

#variable "create_vpc" {
#  type    = bool
#  default = false
#}

variable "vpc_id" {
  type    = string
  default = ""
}

