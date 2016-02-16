resource "aws_route53_record" "jenkins-demo-www" {
  zone_id = "${var.aws_zone_id}"
  name = "${var.demo_name}.${var.domain_name}"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.jenkins-demo-master.public_ip}"]
}
