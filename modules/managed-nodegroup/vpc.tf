#module "vpc" {
#  #count = var.create_vpc == true ? 1 : 0
#  source = "git@github.com:/infracloudio/terraform-aws-vpc"
#
#  name                 = local.name
#  cidr                 = var.vpc_cidr
#  azs                  = local.azs
#  private_subnets      = var.private_subnets
#  public_subnets       = var.public_subnets
#  enable_nat_gateway   = true
#  single_nat_gateway   = true
#  enable_dns_hostnames = true
#
#  enable_flow_log                      = true
#  create_flow_log_cloudwatch_iam_role  = true
#  create_flow_log_cloudwatch_log_group = true
#
#  public_subnet_tags = {
#    "kubernetes.io/cluster/${local.name}" = "shared"
#    "kubernetes.io/role/elb"              = 1
#  }
#
#  private_subnet_tags = {
#    "kubernetes.io/cluster/${local.name}" = "shared"
#    "kubernetes.io/role/internal-elb"     = 1
#  }
#
#  tags = local.tags
#}

module "vpc_cni_irsa" {
  source = "git@github.com:/infracloudio/terraform-aws-iam//examples/iam-role-for-service-accounts-eks"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}
