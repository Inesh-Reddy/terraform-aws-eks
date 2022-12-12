module "eks-self-managed-ng" {
  source = "../../modules/self-managed-nodegroup"

  ami                             = var.ami
  name                            = var.name
  eks_version                     = var.eks_version
  instance_type                   = var.instance_type
  number_of_azs                   = var.number_of_azs
  desired_size                    = var.desired_size
  region                          = var.region
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  vpc_id = var.vpc_id
  private_subnets = var.private_subnets
}
