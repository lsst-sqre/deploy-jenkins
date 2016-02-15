variable "aws_access_key" {
    description = "AWS access key id."
}

variable "aws_secret_key" {
    description = "AWS secret access key."
}

variable "aws_default_region" {
    description = "AWS region to launch servers."
    default = "us-east-1"
}

variable "demo_name" {
    description = "AWS tag name to use on resources."
    default = "jenkins-demo"
}

variable "aws_zone_id" {
    description = "route53 Hosted Zone ID to manage DNS records in."
}

variable "domain_name" {
    description = "DNS domain name to use when creating route53 records."
    default = "lsst.codes"
}
