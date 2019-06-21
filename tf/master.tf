resource "helm_release" "jenkins" {
  name      = "jenkins"
  chart     = "stable/jenkins"
  namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
  version   = "1.3.1"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.jenkins_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
  ]
}

data "template_file" "jenkins_values" {
  template = "${file("${path.module}/charts/jenkins.yaml")}"

  vars {
    jenkins_fqdn           = "${local.master_fqdn}"
    jenkins_secret_name    = "${kubernetes_secret.jenkins_tls.metadata.0.name}"
    casc_vault_secret_name = "${kubernetes_secret.casc_vault.metadata.0.name}"
    vault_root             = "${local.vault_root}"
  }
}

resource "kubernetes_secret" "jenkins_tls" {
  metadata {
    name      = "jenkins-tls"
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
  }

  data {
    tls.crt = "${local.tls_crt}"
    tls.key = "${local.tls_key}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}

resource "kubernetes_secret" "casc_vault" {
  metadata {
    name      = "casc-vault"
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
  }

  data {
    CASC_VAULT_TOKEN = "${local.casc_vault_token}"
  }
}

resource "aws_route53_record" "jenkins" {
  count   = "${var.dns_enable ? 1 : 0}"
  zone_id = "${var.aws_zone_id}"

  name    = "${local.master_fqdn}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${local.nginx_ingress_hostname}"]
}
