resource "kubernetes_namespace" "metrics_server" {
  metadata {
    name = "${local.metrics_server_k8s_namespace}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}

resource "helm_release" "metrics_server" {
  name      = "metrics-server"
  chart     = "stable/metrics-server"
  namespace = "${kubernetes_namespace.metrics_server.metadata.0.name}"
  version   = "2.8.2"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.metrics_server_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
  ]
}

data "template_file" "metrics_server_values" {
  template = "${file("${path.module}/charts/metrics-server.yaml")}"
}
