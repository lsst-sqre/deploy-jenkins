resource "helm_release" "metrics_server" {
  name      = "metrics-server"
  chart     = "stable/metrics-server"
  namespace = "kube-system"
  version   = "2.6.0"

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
