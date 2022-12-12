provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

resource "helm_release" "kyverno" {
  namespace        = "kyverno"
  create_namespace = true

  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno"
  version    = "2.6.0"


  # Deploys Kyverno in HA Mode
  #set {
  #  name  = "replicaCount"
  #  value = 3
  #}

  depends_on = [
    module.eks.eks_managed_node_groups
  ]

}

