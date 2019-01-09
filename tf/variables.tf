variable "aws_default_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

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

variable "scipipe_publish_region" {
  description = "aws region of scipipe-publish deploy tf s3 remote state bucket."
}

variable "scipipe_publish_bucket" {
  description = "scipipe-publish deploy tf s3 remote state bucket."
}

variable "scipipe_publish_key" {
  description = "scipipe-publish deploy tf s3 remote state object key."
}

locals {
  # remove "<env>-" prefix for production
  dns_prefix = "${replace("${var.env_name}-", "jenkins-prod-", "")}"

  master_fqdn = "${local.dns_prefix}${var.service_name}.${var.domain_name}"
}
