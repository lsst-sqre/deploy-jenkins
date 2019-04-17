resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }

  depends_on = ["module.eks"]
}
