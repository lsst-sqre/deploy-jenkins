output "JENKINS_IP" {
  value = "${aws_eip.jenkins-demo-master.public_ip}"
}

output "JENKINS_FQDN" {
  value = "${aws_route53_record.jenkins-demo-master.fqdn}"
}

output "SQUASH_IP" {
  value = "${aws_eip.jenkins-demo-squash.public_ip}"
}

output "SQUASH_FQDN" {
  value = "${aws_route53_record.jenkins-demo-squash.fqdn}"
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
  value = "${var.aws_default_region}"
}

output "DEMO_NAME" {
  value = "${var.demo_name}"
}

output "RDS_FQDN" {
  value = "${aws_route53_record.jenkins-demo-qadb.fqdn}"
}

output "RDS_PASSWORD" {
  sensitive = true
  value = "${var.rds_password}"
}

output "BOKEH_FQDN" {
  value = "${aws_route53_record.jenkins-demo-bokeh.fqdn}"
}

output "DOMAIN_NAME" {
  value = "${var.domain_name}"
}
