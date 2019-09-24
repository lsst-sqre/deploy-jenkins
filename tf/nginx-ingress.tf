locals {
  nginx_ingress_ip       = "${lookup(data.kubernetes_service.nginx_ingress.load_balancer_ingress[0], "ip")}"
  nginx_ingress_hostname = "${lookup(data.kubernetes_service.nginx_ingress.load_balancer_ingress[0], "hostname")}"
}

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
  version   = "1.14.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.nginx_ingress_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",

    # serviceMonitor CRD
    "helm_release.prometheus_operator",
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
    "null_resource.eks_ready",
    "helm_release.nginx_ingress",
  ]
}

# nginx dashboard copied from:
# https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.yaml
data "template_file" "nginx_ingress_grafana_dashboard" {
  template = "${file("${path.module}/grafana-dashboards/nginx.json")}"

  vars {
    DS_PROMETHEUS = "Prometheus"
  }
}

resource "kubernetes_config_map" "nginx_ingress_grafana_dashboard" {
  metadata {
    name      = "nginx-ingress-grafana-dashboard"
    namespace = "${kubernetes_namespace.prometheus.metadata.0.name}"

    labels {
      grafana_dashboard = "1"
    }
  }

  data {
    # .json extension seems to be required
    nginx.json = "${data.template_file.nginx_ingress_grafana_dashboard.rendered}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}
