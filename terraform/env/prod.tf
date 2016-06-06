resource "aws_route53_record" "jenkins-demo-master" {
  name = "ci.${var.domain_name}"
}

resource "aws_route53_record" "jenkins-demo-squash" {
  name = "squash.${var.domain_name}"
}

resource "aws_route53_record" "jenkins-demo-bokeh" {
  name = "bokeh.${var.domain_name}"
}
