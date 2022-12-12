locals {
  name = "kyverno-eks-rs"
  tags = {
    GithubRepo = "https://github.com/infracloudio/terraform-aws-eks"
    ManagedBy  = "terraform"
    Team       = "inception"
  }
}
module "eks_managed_ng" {
  source = "../../modules/managed-nodegroup"
  cluster_name                    = "kyverno-eks-rs"
  eks_version                     = "1.23"
  region                          = "us-east-2"
  instance_types                  = ["t3.medium"]
  number_of_azs                   = 3
  desired_size                    = 1
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  eks_read_write_role_creation    = false #creates read-write access role to cluster
  eks_read_only_role_creation     = false #creates read-only access role to cluster
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  #vpc_cidr                        = var.vpc_cidr
  #create_vpc                      = var.create_vpc
}

module "vpc" {
  #count = var.create_vpc == true ? 1 : 0
  source = "git@github.com:/infracloudio/terraform-aws-vpc?ref=vpc-revamp-for-integration"
  region               = "us-east-2"
  name                 = "kyverno-eks-rs"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-2a","us-east-2b","us-east-2c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = local.tags
}

module "vpc_cni_irsa" {
  source = "git@github.com:/infracloudio/terraform-aws-iam//examples/iam-role-for-service-accounts-eks"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_managed_ng.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}
