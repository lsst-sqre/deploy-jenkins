resource "aws_db_instance" "jenkins-demo" {
  allocated_storage = 100
  storage_type      = "gp2"
  engine            = "mariadb"

  #  aws rds describe-db-engine-versions --engine mariadb
  engine_version    = "10.1.19"
  instance_class    = "db.m4.large"
  identifier        = "${var.demo_name}"
  name              = "qadb"
  username          = "admin"
  password          = "${var.rds_password}"
  apply_immediately = true

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = false

  parameter_group_name      = "${aws_db_parameter_group.jenkins-demo.id}"
  final_snapshot_identifier = "${var.demo_name}-final"
  skip_final_snapshot       = false
  copy_tags_to_snapshot     = true
  backup_retention_period   = 30
  vpc_security_group_ids    = ["${aws_security_group.jenkins-demo-internal.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.jenkins-demo.id}"
  multi_az                  = false
  backup_window             = "07:00-07:55"
  maintenance_window        = "Tue:08:00-Tue:11:00"
}

resource "aws_db_parameter_group" "jenkins-demo" {
  name   = "${var.demo_name}-qadb"
  family = "mariadb10.1"

  # apply changes immediately by invoking a reboot

  parameter {
    name = "max_allowed_packet"

    # 1GiB is the largest possible value
    value        = "1073741824"
    apply_method = "immediate"
  }
  parameter {
    name = "innodb_log_file_size"

    # transactions must be < 10% of the log size
    # value is 256MiB * 10
    value = "2684354560"

    # this param can not be applied immediately
    apply_method = "pending-reboot"
  }
  tags {
    Name = "${var.demo_name}"
  }
}

resource "aws_subnet" "jenkins-demo-db1" {
  vpc_id                  = "${aws_vpc.jenkins-demo.id}"
  availability_zone       = "${var.aws_default_region}b"
  cidr_block              = "192.168.42.0/24"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.demo_name}-db1"
  }
}

resource "aws_subnet" "jenkins-demo-db2" {
  vpc_id                  = "${aws_vpc.jenkins-demo.id}"
  availability_zone       = "${var.aws_default_region}c"
  cidr_block              = "192.168.43.0/24"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.demo_name}-db2"
  }
}

resource "aws_db_subnet_group" "jenkins-demo" {
  name        = "${var.demo_name}"
  description = "Our main group of subnets"
  subnet_ids  = ["${aws_subnet.jenkins-demo-db1.id}", "${aws_subnet.jenkins-demo-db2.id}"]

  tags {
    Name = "QA DB subnet group"
  }
}

resource "aws_route53_record" "jenkins-demo-qadb" {
  zone_id = "${var.aws_zone_id}"
  name    = "${var.demo_name}-qadb.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_db_instance.jenkins-demo.address}"]
}

resource "aws_iam_user" "qadb-backup" {
  name = "${var.demo_name}-qadb-backup"
}

resource "aws_iam_access_key" "qadb-backup" {
  user = "${aws_iam_user.qadb-backup.name}"
}

# base bucket name on qadb FQDN to prevent dumps from test instances
# accdientially getting mixed in with the production backups.
resource "aws_s3_bucket" "qadb-backup" {
  region        = "${var.aws_default_region}"
  bucket        = "${var.demo_name}-qadb.${var.domain_name}-backups"
  force_destroy = false
}

resource "aws_iam_user_policy" "qadb-backup" {
  name = "${aws_iam_user.qadb-backup.name}-policy"
  user = "${aws_iam_user.qadb-backup.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.qadb-backup.arn}/*"
    },
    {
      "Sid": "2",
      "Effect": "Allow",
      "Action": [
        "s3:ListObjects",
        "s3:ListBucket"
      ],
      "Resource": "${aws_s3_bucket.qadb-backup.arn}"
    }
  ]
}
EOF
}

output "RDS_FQDN" {
  value = "${aws_route53_record.jenkins-demo-qadb.fqdn}"
}

output "RDS_PASSWORD" {
  sensitive = true
  value     = "${var.rds_password}"
}

output "RDS_BACKUP_AWS_USER" {
  value = "${aws_iam_user.qadb-backup.name}"
}

output "RDS_BACKUP_S3_BUCKET" {
  value = "${aws_s3_bucket.qadb-backup.id}"
}

output "RDS_BACKUP_AWS_ACCESS_KEY_ID" {
  sensitive = true
  value     = "${aws_iam_access_key.qadb-backup.id}"
}

output "RDS_BACKUP_AWS_SECRET_ACCESS_KEY" {
  sensitive = true
  value     = "${aws_iam_access_key.qadb-backup.secret}"
}
