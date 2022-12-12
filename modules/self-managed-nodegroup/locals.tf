locals {
  name            = var.name
  cluster_version = var.eks_version
  region          = var.region

  tags = {
    GithubRepo = "https://github.com/infracloudio/terraform-aws-eks"
    ManagedBy  = "terraform"
    Team       = "inception"
  }
}

locals {
  azs = var.number_of_azs == 1 ? ["${var.region}a"] : var.number_of_azs == 2 ? ["${var.region}a", "${var.region}b"] : ["${var.region}a", "${var.region}b", "${var.region}c"]
}

locals {
  bottlerocket = {
    name = "bottlerocket-self-mng"

    platform      = "bottlerocket"
    ami_id        = data.aws_ami.eks_default_bottlerocket.id
    instance_type = var.instance_type
    desired_size  = var.desired_size

    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]
    network_interfaces = [
      {
        device_index                = 0
        associate_public_ip_address = false
      }
    ]

    bootstrap_extra_args = <<-EOT
     # The admin host container provides SSH access and runs with "superpowers".
     # It is disabled by default, but can be disabled explicitly.
     [settings.host-containers.admin]
     enabled = false

     # The control host container provides out-of-band access via SSM.
     # It is enabled by default, and can be disabled if you do not expect to use SSM.
     # This could leave you with no way to access the API and change settings on an existing node!
     [settings.host-containers.control]
     enabled = true

     [settings.kubernetes.node-labels]
     ingress = "allowed"
     EOT
  }

  amazon_linux_ami = {
    name = "amazon-linux-self-mng"

    platform      = "linux"
    ami_id        = data.aws_ami.eks_default.id
    instance_type = var.instance_type
    desired_size  = var.desired_size

    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]
    network_interfaces = [
      {
        device_index                = 0
        associate_public_ip_address = false
      }
    ]
    bootstrap_extra_args = ""
  }
}
