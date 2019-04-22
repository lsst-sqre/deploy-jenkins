locals {
  worker_groups = [
    {
      instance_type        = "${var.worker_instance_type}"
      root_volume_size     = "${var.worker_root_volume_size}"
      asg_desired_capacity = 1
      asg_max_size         = 6
      autoscaling_enabled  = true
      rotect_from_scale_in = true
      subnets              = "${aws_subnet.jenkins_workers_c.id}"
    },
  ]

  # recent versions of eks are creating a gp2 sc by default; attempting to
  # declare our own causes an error.
  k8s_storage_class = "gp2"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "3.0.0"

  cluster_name    = "${local.k8s_cluster_name}"
  cluster_version = "1.12"

  subnets = [
    "${aws_subnet.jenkins-demo.id}",
    "${aws_subnet.jenkins_workers_c.id}",
    "${aws_subnet.jenkins_workers_d.id}",
  ]

  tags = {
    Name     = "${local.k8s_cluster_name}"
    env_name = "${var.env_name}"
  }

  vpc_id = "${aws_vpc.jenkins-demo.id}"

  worker_groups      = "${local.worker_groups}"
  worker_group_count = "1"

  # allow communication between worker nodes and jenkins master ec2 instance
  cluster_security_group_id = "${aws_security_group.jenkins-demo-internal.id}"
  worker_security_group_id  = "${aws_security_group.jenkins-demo-internal.id}"

  #worker_additional_security_group_ids = [
  #  "${aws_security_group.jenkins-demo-internal.id}",
  #]

  write_kubeconfig = true
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
}

# if vpc networking related resources are destroyed down before k8s resources,
# eks might break...
# And the k8s api seems to like to timeout right after eks comes up
resource "null_resource" "eks_ready" {
  depends_on = [
    "module.eks",
    "aws_key_pair.jenkins-demo",
    "aws_vpc.jenkins-demo",
    "aws_internet_gateway.jenkins-demo",
    "aws_vpc_dhcp_options.jenkins",
    "aws_vpc_dhcp_options_association.jenkins",
    "aws_route53_zone.jenkins-internal",
    "aws_route53_record.jenkins-master-internal",
    "aws_subnet.jenkins-demo",
    "aws_subnet.jenkins_workers_c",
    "aws_subnet.jenkins_workers_d",
    "aws_route_table.jenkins-demo",
    "aws_main_route_table_association.jenkins-demo",
    "aws_network_acl.jenkins-demo",
    "aws_eip.jenkins-demo-master",
    "aws_security_group.jenkins-demo-ssh",
    "aws_security_group.jenkins-demo-http",
    "aws_security_group.jenkins-demo-slaveport",
    "aws_security_group.jenkins-demo-internal",
  ]

  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
for i in `seq 1 10`; do \
kubectl --kubeconfig ${null_resource.eks_ready.triggers.config_path} get ns && break || \
sleep 10; \
done; \
EOS

    interpreter = ["/bin/sh", "-c"]
  }

  triggers {
    host                   = "${module.eks.cluster_endpoint}"
    config_path            = "${module.eks.kubeconfig_filename}"
    cluster_ca_certificate = "${base64decode(module.eks.cluster_certificate_authority_data)}"
  }
}

provider "kubernetes" {
  version = "~> 1.5.2"

  host                   = "${module.eks.cluster_endpoint}"
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
    config_path            = "${module.eks.kubeconfig_filename}"
    load_config_file       = true
    cluster_ca_certificate = "${base64decode(module.eks.cluster_certificate_authority_data)}"
  }
}

resource "kubernetes_namespace" "tiller" {
  metadata {
    name = "${local.tiller_k8s_namespace}"
  }

  depends_on = [
    "null_resource.eks_ready",
  ]
}

module "tiller" {
  source          = "git::https://github.com/lsst-sqre/terraform-tinfoil-tiller.git//?ref=master"
  namespace       = "${kubernetes_namespace.tiller.metadata.0.name}"
  service_account = "tiller"
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
    "null_resource.eks_ready",
    "module.tiller",
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
serviceMonitor:
  enabled: true
#nodeSelector:
#  kubernetes.io/role: master
#tolerations:
#  - key: node-role.kubernetes.io/master
#    effect: NoSchedule
END

  vars {
    aws_region   = "us-east-1"
    cluster_name = "${module.eks.cluster_id}"
  }
}

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
  template = <<END
#service:
#  labels:
#    kubernetes.io/name: "Metrics-server"
#    kubernetes.io/cluster-service: "true"
args:
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP
END
}
