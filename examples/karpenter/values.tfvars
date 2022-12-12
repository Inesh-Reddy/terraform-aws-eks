name                            = "eks-karpenter"
eks_version                     = "1.23"
instance_type                   = ["t3.small"]
desired_size                    = 1
region                          = "ap-southeast-1"
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true
#vpc_cidr                        = "10.0.0.0/16"
vpc_id                          = "vpc-062abad15157909b6"
private_subnets                 = ["subnet-05b716b3fccced726", "subnet-0d97128f4de688c6f", "subnet-0a9e7a7fe8f29632d"]
