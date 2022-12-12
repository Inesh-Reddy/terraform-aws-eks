variable "eks_version" {
  type    = string
  default = "1.22"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = list(string)
  default = ["t3.small"]
}

variable "desired_size" {
  type    = number
  default = 1
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "name" {
  type    = string
  default = "inception-eks-karpenter"
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
variable "vpc_id" {
  type        = string
  default     = ""
}
