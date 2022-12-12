module "eks-fargate" {
  source = "../../modules/fargate"

  cluster_name                    = var.cluster_name
  region                          = var.region
  number_of_azs                   = var.number_of_azs
  eks_version                     = var.eks_version
  instance_types                  = var.instance_types
  desired_size                    = var.desired_size
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  vpc_cidr                        = var.vpc_cidr
}

