provider "aws" {
  region = var.region
}

locals {
  name            = var.cluster_name
  cluster_version = var.eks_version
  region          = var.region
  

  tags = {
    GithubRepo = "https://github.com/infracloudio/terraform-aws-eks"
    ManagedBy  = "terraform"
  }
}

data "aws_eks_cluster" "default" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
}
