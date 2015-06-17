provider "aws" {
    region = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

resource "aws_key_pair" "jenkins-demo" {
    key_name = "${var.demo_name}"
    public_key = "${file("../jenkins_demo/templates/id_rsa.pub")}"
}

resource "aws_vpc" "jenkins-demo" {
    cidr_block = "192.168.123.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags {
        Name = "jenkins-demo"
    }
}

resource "aws_internet_gateway" "jenkins-demo" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"

    tags {
        Name = "jenkins-demo"
    }
}

resource "aws_subnet" "jenkins-demo" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    cidr_block = "192.168.123.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "jenkins-demo"
    }
}

resource "aws_route_table" "jenkins-demo" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.jenkins-demo.id}"
    }

    tags {
        Name = "jenkins-demo"
    }
}

resource "aws_main_route_table_association" "jenkins-demo" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    route_table_id = "${aws_route_table.jenkins-demo.id}"
}

resource "aws_network_acl" "jenkins-demo" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    subnet_ids = ["${aws_subnet.jenkins-demo.id}"]

    ingress {
        rule_no = 100
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_block = "0.0.0.0/0"
        action = "allow"
    }

    egress {
        rule_no = 100
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_block = "0.0.0.0/0"
        action = "allow"
    }

    tags {
        Name = "jenkins-demo"
    }
}

resource "aws_eip" "jenkins-demo-master" {
    vpc = true
}

resource "aws_security_group" "jenkins-demo-ssh" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    name = "jenkins-demo-ssh"
    description = "allow external ssh"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "jenkins-demo-ssh"
    }
}

resource "aws_security_group" "jenkins-demo-http" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    name = "jenkins-demo-http"
    description = "allow external http/https"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 433
        to_port = 433
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "jenkins-demo-http"
    }
}

resource "aws_security_group" "jenkins-demo-internal" {
    vpc_id = "${aws_vpc.jenkins-demo.id}"
    name = "jenkins-demo-internal"
    description = "allow all jenkins-demo internal traffic"

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${aws_subnet.jenkins-demo.cidr_block}"]
    }

    # allow all output traffic from the VPC
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "jenkins-demo-internal"
    }
}
