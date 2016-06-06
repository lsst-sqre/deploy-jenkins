resource "aws_route53_record" "jenkins-demo-master" {
  zone_id = "${var.aws_zone_id}"
  name = "${var.demo_name}-ci.${var.domain_name}"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.jenkins-demo-master.public_ip}"]
}

resource "aws_route53_record" "jenkins-demo-squash" {
  zone_id = "${var.aws_zone_id}"
  name = "${var.demo_name}-squash.${var.domain_name}"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.jenkins-demo-squash.public_ip}"]
}

resource "aws_route53_record" "jenkins-demo-bokeh" {
  zone_id = "${var.aws_zone_id}"
  name = "${var.demo_name}-bokeh.${var.domain_name}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_route53_record.jenkins-demo-squash.fqdn}"]
}
