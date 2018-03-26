resource "aws_route53_record" "jenkins-demo-master" {
  name = "ts-ci.${var.domain_name}"
}
