resource "aws_route53_record" "jenkins-demo-master" {
  name = "ci.${var.domain_name}"
}
