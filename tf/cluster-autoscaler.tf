resource "kubernetes_namespace" "cluster_autoscaler" {
  metadata {
    name = "${local.cluster_autoscaler_k8s_namespace}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}

resource "helm_release" "cluster_autoscaler" {
  name      = "cluster-autoscaler"
  chart     = "stable/cluster-autoscaler"
  namespace = "${kubernetes_namespace.cluster_autoscaler.metadata.0.name}"
  version   = "0.10.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.cluster_autoscaler_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",

    # serviceMonitor CRD
    "helm_release.prometheus_operator",
  ]
}

data "template_file" "cluster_autoscaler_values" {
  template = "${file("${path.module}/charts/cluster-autoscaler.yaml")}"

  vars {
    aws_region   = "us-east-1"
    cluster_name = "${module.eks.cluster_id}"
  }
}
