module "eks_managed_ng" {
  source = "../../modules/managed-nodegroup"

  cluster_name                    = var.cluster_name
  eks_version                     = var.eks_version
  region                          = var.region
  instance_types                  = var.instance_types
  number_of_azs                   = var.number_of_azs
  desired_size                    = var.desired_size
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  eks_read_write_role_creation    = var.eks_read_write_role_creation
  eks_read_only_role_creation     = var.eks_read_only_role_creation
  vpc_id = var.vpc_id
  private_subnets = var.private_subnets
  #vpc_cidr                        = var.vpc_cidr
  #create_vpc                      = var.create_vpc
}
