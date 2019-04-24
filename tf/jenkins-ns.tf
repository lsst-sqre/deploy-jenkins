resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}
