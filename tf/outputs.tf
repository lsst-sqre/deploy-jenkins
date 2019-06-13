output "JENKINS_IP" {
  value = "${aws_eip.jenkins-demo-master.public_ip}"
}

output "JENKINS_FQDN" {
  value = "${local.master_alias}"
}

output "JENKINS_MASTER_INTERNAL_IP" {
  value = "${local.jenkins_master_internal_ip}"
}

output "JENKINS_INTERNAL_DOMAIN" {
  value = "${local.jenkins_internal_domain}"
}

output "SUBNET_ID" {
  value = "${aws_subnet.jenkins-demo.id}"
}

output "SECURITY_GROUP_ID_SSH" {
  value = "${aws_security_group.jenkins-demo-ssh.id}"
}

output "SECURITY_GROUP_ID_HTTP" {
  value = "${aws_security_group.jenkins-demo-http.id}"
}

output "SECURITY_GROUP_ID_SLAVEPORT" {
  value = "${aws_security_group.jenkins-demo-slaveport.id}"
}

output "SECURITY_GROUP_ID_INTERNAL" {
  value = "${aws_security_group.jenkins-demo-internal.id}"
}

output "AWS_DEFAULT_REGION" {
  value = "${local.aws_default_region}"
}

output "ENV_NAME" {
  value = "${var.env_name}"
}

output "DOMAIN_NAME" {
  value = "${var.domain_name}"
}

output "GROUP_NAME" {
  value = "${var.group_name}"
}

output "kubeconfig" {
  # not actually sensitive... just a lot of output
  sensitive   = true
  description = "kubectl config file contents for this EKS cluster."
  value       = "${module.eks.kubeconfig}"
}

output "kubeconfig_filename" {
  description = "The filename of the generated kubectl config."
  value       = "${module.eks.kubeconfig_filename}"
}

output "grafana_admin_pass" {
  description = "grafana admin user account password."
  sensitive   = true
  value       = "${local.grafana_admin_pass}"
}

output "grafana_admin_user" {
  description = "name of the grafana admin user account."
  value       = "${local.grafana_admin_user}"
}
