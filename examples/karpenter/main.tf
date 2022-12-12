module "eks-karpenter" {
  source = "../../modules/karpenter"

  name                            = var.name
  eks_version                     = var.eks_version
  instance_type                   = var.instance_type
  desired_size                    = var.desired_size
  region                          = var.region
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  #vpc_cidr                        = var.vpc_cidr
  vpc_id = var.vpc_id
  private_subnets = var.private_subnets

}
