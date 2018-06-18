variable "aws_access_key" {
  description = "AWS access key id."
}

variable "aws_secret_key" {
  description = "AWS secret access key."
}

variable "aws_default_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_zone_id" {
  description = "route53 Hosted Zone ID to manage DNS records in."
  default     = "Z3TH0HRSNU67AM"
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
  default     = "lsst.codes"
}

# remove "<env>-" prefix for production
data "template_file" "fqdn" {
  template = "${replace("${var.env_name}-${var.service_name}.${var.domain_name}", "jenkins-prod-", "")}"
}

data "template_file" "publish_release_bucket" {
  template = "${var.env_name}-publish-release-tf"
}
