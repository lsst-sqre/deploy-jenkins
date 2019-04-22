# https://cloud.google.com/community/tutorials/nginx-ingress-gke

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "${local.nginx_ingress_k8s_namespace}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  chart     = "stable/nginx-ingress"
  namespace = "${kubernetes_namespace.nginx_ingress.metadata.0.name}"
  version   = "1.6.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.nginx_ingress_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
  ]
}

data "template_file" "nginx_ingress_values" {
  template = "${file("${path.module}/charts/nginx-ingress.yaml")}"
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = "${kubernetes_namespace.nginx_ingress.metadata.0.name}"
  }

  depends_on = [
    "helm_release.nginx_ingress",
  ]
}

locals {
  nginx_ingress_ip       = "${lookup(data.kubernetes_service.nginx_ingress.load_balancer_ingress[0], "ip")}"
  nginx_ingress_hostname = "${lookup(data.kubernetes_service.nginx_ingress.load_balancer_ingress[0], "hostname")}"
}
