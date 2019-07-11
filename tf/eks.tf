locals {
  worker_groups = [
    {
      name                  = "agents"
      instance_type         = "${var.worker_instance_type}"
      root_volume_size      = "${var.worker_root_volume_size}"
      asg_min_size          = 0
      asg_desired_capacity  = 0
      asg_max_size          = 6
      autoscaling_enabled   = true
      protect_from_scale_in = true
      subnets               = "${aws_subnet.jenkins_workers_c.id}"
      kubelet_extra_args    = "--node-labels=nodegroup=agent"
    },
    {
      name             = "admin"
      instance_type    = "t3.medium"
      root_volume_size = "32"

      # eks needs at least one node online for dns pods/etc. or it bricks
      asg_min_size          = 1
      asg_desired_capacity  = 1
      asg_max_size          = 2
      autoscaling_enabled   = true
      protect_from_scale_in = true
      subnets               = "${aws_subnet.jenkins_workers_c.id}"
      kubelet_extra_args    = "--node-labels=nodegroup=admin"
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
  cluster_version = "1.13"

  write_aws_auth_config = false
  write_kubeconfig      = true

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
  worker_group_count = "${length(local.worker_groups)}"

  # allow communication between worker nodes and jenkins master ec2 instance
  cluster_security_group_id = "${aws_security_group.jenkins-demo-internal.id}"
  worker_security_group_id  = "${aws_security_group.jenkins-demo-internal.id}"

  #worker_additional_security_group_ids = [
  #  "${aws_security_group.jenkins-demo-internal.id}",
  #]

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

  #"module.eks",

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

#resource "aws_cloudwatch_log_group" "eks" {
#  name = "/aws/eks/${local.k8s_cluster_name}/cluster"
#
#  retention_in_days = "7"
#
#  tags = {
#    Name = "${local.k8s_cluster_name}"
#  }
#}

data "aws_eks_cluster" "cluster" {
  name = "${module.eks.cluster_id}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${module.eks.cluster_id}"
}

provider "kubernetes" {
  version = "~> 1.8.0"

  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)}"
  host                   = "${data.aws_eks_cluster.cluster.endpoint}"
  load_config_file       = false
  token                  = "${data.aws_eks_cluster_auth.cluster.token}"
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
  source          = "git::https://github.com/lsst-sqre/terraform-tinfoil-tiller.git//?ref=0.10.x"
  namespace       = "${kubernetes_namespace.tiller.metadata.0.name}"
  service_account = "tiller"
}

provider "helm" {
  version = "~> 0.10.0"

  service_account = "${module.tiller.service_account}"
  namespace       = "${module.tiller.namespace}"
  install_tiller  = false

  kubernetes {
    cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)}"
    host                   = "${data.aws_eks_cluster.cluster.endpoint}"
    load_config_file       = false
    token                  = "${data.aws_eks_cluster_auth.cluster.token}"
  }
}
