locals {
  master_aws_region = "${data.aws_region.current.name}"
  master_aws_zone   = "${local.master_aws_region}c"

  # XXX param lookup doesn't work here -- WHY???
  #vol_size          = "${data.aws_ebs_volume.jenkins_master.size}Gi"
  vol_size = "750Gi"
}

resource "helm_release" "jenkins" {
  name      = "jenkins"
  chart     = "stable/jenkins"
  namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
  version   = "1.5.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.jenkins_values.rendered}",
  ]

  depends_on = [
    "null_resource.eks_ready",
    "module.tiller",
    "kubernetes_persistent_volume_claim.master_pvc",
  ]
}

data "template_file" "jenkins_values" {
  template = "${file("${path.module}/charts/jenkins.yaml")}"

  vars {
    admin_email            = "nobody@${var.domain_name}"
    casc_vault_secret_name = "${kubernetes_secret.casc_vault.metadata.0.name}"
    jenkins_fqdn           = "${local.master_fqdn}"
    jenkins_secret_name    = "${kubernetes_secret.jenkins_tls.metadata.0.name}"
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

resource "aws_ebs_volume" "jenkins_master" {
  availability_zone = "${local.master_aws_zone}"
  size              = 750

  tags = {
    Name = "jenkins-data"
  }
}

data "aws_ebs_volume" "jenkins_master" {
  filter {
    name   = "availability-zone"
    values = ["${local.master_aws_zone}"]
  }

  filter {
    name   = "volume-id"
    values = ["${aws_ebs_volume.jenkins_master.id}"]
  }
}

resource "kubernetes_persistent_volume" "master_pv" {
  metadata {
    name = "master-pv"
  }

  spec {
    capacity = {
      storage = "${local.vol_size}"
    }

    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "${data.aws_ebs_volume.jenkins_master.volume_type}"

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      aws_elastic_block_store {
        fs_type = "ext4"

        #volume_id = "aws://us-east-1c/vol-085e02406057778ce"
        volume_id = "aws://${data.aws_ebs_volume.jenkins_master.availability_zone}/${data.aws_ebs_volume.jenkins_master.id}"
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "failure-domain.beta.kubernetes.io/zone"
            operator = "In"
            values   = ["${data.aws_ebs_volume.jenkins_master.availability_zone}"]
          }

          match_expressions {
            key      = "failure-domain.beta.kubernetes.io/region"
            operator = "In"
            values   = ["${data.aws_region.current.name}"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "master_pvc" {
  metadata {
    name      = "master-pvc"
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
  }

  spec {
    volume_name        = "${kubernetes_persistent_volume.master_pv.metadata.0.name}"
    access_modes       = ["${kubernetes_persistent_volume.master_pv.spec.0.access_modes}"]
    storage_class_name = "${kubernetes_persistent_volume.master_pv.spec.0.storage_class_name}"

    resources {
      requests {
        storage = "${kubernetes_persistent_volume.master_pv.spec.0.capacity.storage}"
      }
    }
  }
}

# https://grafana.com/grafana/dashboards/9964
data "template_file" "jenkins_grafana_dashboard" {
  template = "${file("${path.module}/grafana-dashboards/jenkins-performance-and-health-overview_rev1.json")}"

  vars {
    DS_PROMETHEUS = "Prometheus"
  }
}

resource "kubernetes_config_map" "jenkins_grafana_dashboard" {
  metadata {
    name      = "jenkins-grafana-dashboard"
    namespace = "${kubernetes_namespace.prometheus.metadata.0.name}"

    labels {
      grafana_dashboard = "1"
    }
  }

  data {
    # .json extension seems to be required
    jenkins-performance-and-health-overview_rev1.json = "${data.template_file.jenkins_grafana_dashboard.rendered}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}
