locals {
  prometheus_fqdn = "${local.dns_prefix}prometheus-${var.deploy_name}.${var.domain_name}"
  grafana_fqdn    = "${local.dns_prefix}grafana-${var.deploy_name}.${var.domain_name}"
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
  version   = "6.4.2"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.prometheus_operator_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
  ]
}

data "template_file" "prometheus_operator_values" {
  template = "${file("${path.module}/charts/prometheus-operator.yaml")}"

  vars {
    client_id                = "${local.grafana_oauth_client_id}"
    client_secret            = "${local.grafana_oauth_client_secret}"
    grafana_admin_pass       = "${local.grafana_admin_pass}"
    grafana_admin_user       = "${local.grafana_admin_user}"
    grafana_fqdn             = "${local.grafana_fqdn}"
    grafana_secret_name      = "${kubernetes_secret.prometheus_tls.metadata.0.name}"
    prometheus_k8s_namespace = "${kubernetes_namespace.prometheus.metadata.0.name}"
    prometheus_secret_name   = "${kubernetes_secret.prometheus_tls.metadata.0.name}"
    team_ids                 = "${var.grafana_oauth_team_ids}"
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

  depends_on = [
    "null_resource.eks_ready",
  ]
}

resource "helm_release" "prometheus_oauth2_proxy" {
  name      = "prometheus-oauth2-proxy"
  chart     = "stable/oauth2-proxy"
  namespace = "${kubernetes_namespace.prometheus.metadata.0.name}"
  version   = "0.14.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.prometheus_oauth2_proxy_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
  ]
}

data "template_file" "prometheus_oauth2_proxy_values" {
  template = "${file("${path.module}/charts/prometheus-oauth2-proxy.yaml")}"

  vars {
    prometheus_fqdn                = "${local.prometheus_fqdn}"
    prometheus_oauth_client_id     = "${local.prometheus_oauth_client_id}"
    prometheus_oauth_client_secret = "${local.prometheus_oauth_client_secret}"
    prometheus_oauth_github_org    = "${var.prometheus_oauth_github_org}"
    prometheus_secret_name         = "${kubernetes_secret.prometheus_tls.metadata.0.name}"
  }
}

resource "aws_route53_record" "prometheus" {
  count   = "${var.dns_enable ? 1 : 0}"
  zone_id = "${var.aws_zone_id}"

  name    = "${local.prometheus_fqdn}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${local.nginx_ingress_hostname}"]
}

resource "aws_route53_record" "grafana" {
  count   = "${var.dns_enable ? 1 : 0}"
  zone_id = "${var.aws_zone_id}"

  name    = "${local.grafana_fqdn}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${local.nginx_ingress_hostname}"]
}
