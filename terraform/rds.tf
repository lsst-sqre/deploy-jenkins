resource "aws_db_instance" "jenkins-demo" {
    allocated_storage         = 50
    storage_type              = "gp2"
    engine                    = "mariadb"
    engine_version            = "10.0.17"
    instance_class            = "db.m4.large"
    identifier                = "${var.demo_name}"
    name                      = "qadb"
    username                  = "admin"
    password                  = "${var.rds_password}"
    #parameter_group_name     = "default.mysql5.6"
    final_snapshot_identifier = "oops"
    skip_final_snapshot       = false
    copy_tags_to_snapshot     = true
    backup_retention_period   = 30
    vpc_security_group_ids    = [ "${aws_security_group.jenkins-demo-internal.id}" ]
    db_subnet_group_name      = "${aws_db_subnet_group.jenkins-demo.id}"
    multi_az                  = false
}

resource "aws_subnet" "jenkins-demo-db1" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    availability_zone = "${var.aws_default_region}b"
    cidr_block = "192.168.42.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.demo_name}-db1"
    }
}

resource "aws_subnet" "jenkins-demo-db2" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    availability_zone = "${var.aws_default_region}c"
    cidr_block = "192.168.43.0/24"
    map_public_ip_on_launch = false

    tags {
        Name = "${var.demo_name}-db2"
    }
}

resource "aws_db_subnet_group" "jenkins-demo" {
    name = "${var.demo_name}"
    description = "Our main group of subnets"
    subnet_ids = [ "${aws_subnet.jenkins-demo-db1.id}", "${aws_subnet.jenkins-demo-db2.id}" ]
    tags {
        Name = "QA DB subnet group"
    }
}

resource "aws_route53_record" "jenkins-demo-qadb" {
  zone_id = "${var.aws_zone_id}"
  name = "${var.demo_name}-qadb.${var.domain_name}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_db_instance.jenkins-demo.address}"]
}
