module "eks" {
  source = "../.."

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    # Note: https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    node_group_one = {
      desired_size = var.desired_size

      instance_types = var.instance_types
      labels = {
        GithubRepo = "inception-terraform-aws-eks"
      }
      tags = {
        GithubRepo = "https://github.com/infracloudio/terraform-aws-eks"
        ManagedBy  = "terraform"
      }
    }
  }

  fargate_profiles = {

    sample-profile = {
      name = "inception-sample-profile"
      selectors = [
        {
          namespace = "default"
        }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      subnet_ids = [module.vpc.private_subnets[1]]

      tags = {
        GithubRepo = "https://github.com/infracloudio/terraform-aws-eks"
        ManagedBy  = "terraform"
      }
    }
  }

  tags = local.tags
}
