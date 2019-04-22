locals {
  prometheus_fqdn = "prometheus-${local.dns_suffix}"
  grafana_fqdn    = "grafana-${local.dns_suffix}"
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "${local.prometheus_k8s_namespace}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}

resource "helm_release" "prometheus_operator" {
  name      = "prometheus-operator"
  chart     = "stable/prometheus-operator"
  namespace = "${kubernetes_namespace.prometheus.metadata.0.name}"
  version   = "5.2.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.prometheus_operator_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
    "helm_release.nginx_ingress",
  ]
}

data "template_file" "prometheus_operator_values" {
  template = "${file("${path.module}/charts/prometheus-operator.yaml")}"

  vars {
    grafana_fqdn = "${local.grafana_fqdn}"
  }
}

resource "kubernetes_secret" "prometheus_tls" {
  metadata {
    name      = "prometheus-server-tls"
    namespace = "${kubernetes_namespace.prometheus.metadata.0.name}"
  }

  data {
    tls.crt = "${local.tls_crt}"
    tls.key = "${local.tls_key}"
  }
}

resource "helm_release" "prometheus_oauth2_proxy" {
  name      = "prometheus-oauth2-proxy"
  chart     = "stable/oauth2-proxy"
  namespace = "${kubernetes_namespace.prometheus.metadata.0.name}"
  version   = "0.12.1"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.prometheus_oauth2_proxy_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
    "helm_release.nginx_ingress",
  ]
}

data "template_file" "prometheus_oauth2_proxy_values" {
  template = "${file("${path.module}/charts/prometheus-oauth2-proxy.yaml")}"

  vars {
    prometheus_client_id     = "${var.prometheus_client_id}"
    prometheus_client_secret = "${var.prometheus_client_secret}"
    prometheus_fqdn          = "${local.prometheus_fqdn}"
    prometheus_github_org    = "${var.prometheus_github_org}"
  }
}

resource "aws_route53_record" "prometheus" {
  count   = "${var.dns_enable ? 1 : 0}"
  zone_id = "${var.aws_zone_id}"

  name    = "${local.prometheus_fqdn}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${local.nginx_ingress_hostname}"]
}

resource "aws_route53_record" "grafana" {
  count   = "${var.dns_enable ? 1 : 0}"
  zone_id = "${var.aws_zone_id}"

  name    = "${local.grafana_fqdn}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${local.nginx_ingress_hostname}"]
}
