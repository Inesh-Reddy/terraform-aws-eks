resource "kubernetes_role" "namespace-viewer" {
  count = var.eks_read_only_role_creation ? 1 : 0
  metadata {
    name      = "read-only-viewer"
    namespace = "default"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/logs", "pods/attach", "pods/exec", "services", "serviceaccounts", "configmaps", "persistentvolumes", "persistentvolumeclaims", "secrets"]
    verbs      = ["get", "list", "watch", "describe"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch", "describe"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
    verbs      = ["get", "list", "watch", "describe"]
  }
}

resource "kubernetes_role_binding" "namespace-viewer" {
  count = var.eks_read_only_role_creation ? 1 : 0
  metadata {
    name      = "read-only-viewer"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.namespace-viewer[0].metadata[0].name
  }
  subject {
    kind      = "User"
    name      = "read-only"
    api_group = "rbac.authorization.k8s.io"
  }
}
