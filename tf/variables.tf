variable "aws_zone_id" {
  description = "route53 Hosted Zone ID to manage DNS records in."
}

# note that the production name is `jenkins-prod` for backwards compatiblity
variable "env_name" {
  description = "Name of deployment environment."
}

variable "service_name" {
  description = "service / unqualifed hostname"
  default     = "ci"
}

variable "domain_name" {
  description = "DNS domain name to use when creating route53 records."
}

variable "group_name" {
  description = "select group specific configuration."
}

variable "master_fqdn" {
  description = "FQDN jenkins will respond to. If empty (default), it is generated from the env_name, service_name, and domain_name. This is useful to configure jenkins to respond to a DNS alias."
  default     = ""
}

variable "worker_instance_type" {
  default = "c5.2xlarge"
}

variable "worker_root_volume_size" {
  default = "100"
}

variable "jenkins_agent_volume_size" {
  default = "250Gi"
}

locals {
  # remove "<env>-" prefix for production
  dns_prefix = "${replace("${var.env_name}-", "jenkins-prod-", "")}"

  master_fqdn  = "${local.dns_prefix}${var.service_name}.${var.domain_name}"
  master_alias = "${var.master_fqdn != "" ? var.master_fqdn : local.master_fqdn}"
}
