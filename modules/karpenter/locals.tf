locals {
  name            = var.name
  cluster_version = var.eks_version
  region          = var.region
  partition       = data.aws_partition.current.partition

  tags = {
    GithubRepo = "https://github.com/infracloudio/terraform-aws-eks"
    ManagedBy  = "terraform"
    Team       = "inception"
  }
}

