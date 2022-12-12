module "iam-all-ec2-describe-policy" {
  source = "https://github.com/Inesh-Reddy/terraform-aws-iam//examples/iam-all-ec2-describe-policy"
  /* source = "git@github.com:/infracloudio/terraform-aws-iam//examples/iam-all-ec2-describe-policy" */
}

data "aws_partition" "current" {}

locals {
  role_to_user_map = {
    iam-read-write = "read-write",
    iam-read-only  = "read-only"
  }

  role_map_obj = [
    for role_name, user in local.role_to_user_map : {
      rolearn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${role_name}"
      username = user
      groups   = contains(tolist([user]), "read-write") ? tolist(["system:masters"]) : tolist(["none"])
    }
  ]
}

module "iam_iam-eks-describe-cluster" {
  source = "https://github.com/Inesh-Reddy/terraform-aws-iam//examples/iam-eks-describe-cluster-policy"
  /* source = "git@github.com:/infracloudio/terraform-aws-iam//examples/iam-eks-describe-cluster-policy" */
}

resource "aws_iam_policy" "eks_describe_cluster" {
  count       = var.eks_read_write_role_creation || var.eks_read_only_role_creation ? 1 : 0
  name        = "iam-eks-describe-cluster-policy"
  description = "creates a IAM policy with policy passed as input"
  policy      = module.iam_iam-eks-describe-cluster.policy
}

module "iam_iam-assumable-role" {
  count  = var.eks_read_write_role_creation ? 1 : 0
  source = "https://github.com/Inesh-Reddy/terraform-aws-iam//examples/iam-assumable-role"
  /* source = "git@github.com:/infracloudio/terraform-aws-iam//examples/iam-assumable-role" */

  trusted_role_arns = [
    "arn:aws:iam::${var.iam_account_id}:root",
  ]

  create_role = true

  role_name         = "iam-read-write"
  role_requires_mfa = false

  custom_role_policy_arns           = [aws_iam_policy.eks_describe_cluster[0].arn]
  number_of_custom_role_policy_arns = 1
}

module "iam_iam-assumable-role_" {
  count  = var.eks_read_only_role_creation ? 1 : 0
  source = "https://github.com/Inesh-Reddy/terraform-aws-iam//examples/iam-assumable-role"
  /* source = "git@github.com:/infracloudio/terraform-aws-iam//examples/iam-assumable-role" */

  trusted_role_arns = [
    "arn:aws:iam::${var.iam_account_id}:root",
  ]

  create_role = true

  role_name         = "iam-read-only"
  role_requires_mfa = false

  custom_role_policy_arns           = [aws_iam_policy.eks_describe_cluster[0].arn]
  number_of_custom_role_policy_arns = 1
}

