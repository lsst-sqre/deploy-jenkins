resource "aws_route53_record" "jenkins-demo-www" {
  zone_id = "Z3TH0HRSNU67AM"
  name = "${var.demo_name}.lsst.codes"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.jenkins-demo-master.public_ip}"]
}
