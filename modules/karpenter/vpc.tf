#module "vpc" {
#  source  = "terraform-aws-modules/vpc/aws"
#  version = "~> 3.0"
#
#  name = local.name
#  cidr = var.vpc_cidr
#
#  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
#  private_subnets = var.private_subnets
#  public_subnets  = var.public_subnets
#
#  enable_nat_gateway   = true
#  single_nat_gateway   = true
#  enable_dns_hostnames = true
#
#  public_subnet_tags = {
#    "kubernetes.io/cluster/${local.name}" = "shared"
#    "kubernetes.io/role/elb"              = 1
#  }
#
#  private_subnet_tags = {
#    "kubernetes.io/cluster/${local.name}" = "shared"
#    "kubernetes.io/role/internal-elb"     = 1
#    # Tags subnets for Karpenter auto-discovery
#    "karpenter.sh/discovery" = local.name
#  }
#
#  tags = local.tags
#}
#
