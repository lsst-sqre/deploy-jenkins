locals {
  worker_groups = [
    {
      instance_type        = "${var.worker_instance_type}"
      root_volume_size     = "${var.worker_root_volume_size}"
      asg_desired_capacity = 1
      asg_max_size         = 6
      autoscaling_enabled  = true
      rotect_from_scale_in = true
      subnets              = "${aws_subnet.jenkins-demo.id}"
    },
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "3.0.0"

  cluster_name    = "test-eks-cluster"
  cluster_version = "1.12"

  subnets = [
    "${aws_subnet.jenkins-demo.id}",
    "${aws_subnet.jenkins-demo_d.id}",
  ]

  tags = {
    Name = "${var.env_name}"
  }

  vpc_id = "${aws_vpc.jenkins-demo.id}"

  worker_groups      = "${local.worker_groups}"
  worker_group_count = "1"

  # allow communication between worker nodes and jenkins master ec2 instance
  worker_additional_security_group_ids = [
    "${aws_security_group.jenkins-demo-internal.id}",
  ]

  write_kubeconfig = true
}

provider "kubernetes" {
  version = "~> 1.5.2"

  host = "${module.eks.cluster_endpoint}"

  config_path            = "${module.eks.kubeconfig_filename}"
  load_config_file       = true
  cluster_ca_certificate = "${base64decode(module.eks.cluster_certificate_authority_data)}"
}

provider "helm" {
  version = "~> 0.9.0"

  service_account = "${module.tiller.service_account}"
  namespace       = "${module.tiller.namespace}"
  install_tiller  = false

  kubernetes {
    host                   = "${module.eks.cluster_endpoint}"
    config_path            = "${path.module}/kubeconfig_test-eks-cluster"
    cluster_ca_certificate = "${base64decode(module.eks.cluster_certificate_authority_data)}"
  }
}

module "tiller" {
  source          = "git::https://github.com/lsst-sqre/terraform-tinfoil-tiller.git//?ref=master"
  namespace       = "kube-system"
  service_account = "tiller"
}

resource "kubernetes_storage_class" "gp2" {
  # note that storageclass is not namespaced
  metadata {
    name = "gp2"

    labels {
      name = "gp2"
    }

    #annotations {
    #  "storageclass.kubernetes.io/is-default-class" = true
    #}
  }

  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters {
    type   = "gp2"
    fsType = "ext4"
  }

  depends_on = ["module.eks"]
}

resource "helm_release" "cluster_autoscaler" {
  name      = "cluster-autoscaler"
  chart     = "stable/cluster-autoscaler"
  namespace = "kube-system"
  version   = "0.10.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.cluster_autoscaler_values.rendered}",
  ]

  depends_on = [
    "module.tiller",
    "module.eks",
  ]
}

data "template_file" "cluster_autoscaler_values" {
  template = <<END
rbac:
  create: true

sslCertPath: /etc/ssl/certs/ca-bundle.crt

cloudProvider: aws
awsRegion: $${aws_region}

autoDiscovery:
  clusterName: $${cluster_name}
  enabled: true

replicaCount: 1
#nodeSelector:
#  kubernetes.io/role: master
#tolerations:
#  - key: node-role.kubernetes.io/master
#    effect: NoSchedule
END

  vars {
    aws_region = "us-east-1"

    #XXX
    cluster_name = "test-eks-cluster"
  }
}
