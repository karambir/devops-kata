# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "${var.project}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.project}"
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "${var.project}-sg-elb"
  description = "Used in the ubuntu init"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "${var.project}-sg-backend"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_s3_bucket" "lb_logs" {
#   bucket_prefix = "${var.project}"
#   acl           = "private"

#   tags {
#     Name        = "${var.project}"
#     Environment = "${var.project_environment}"
#   }
# }

resource "aws_elb" "web" {
  name_prefix     = "${var.project_short}-"
  internal        = false
  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 6
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  # access_logs {
  #   bucket        = "${aws_s3_bucket.lb_logs.bucket}"
  #   bucket_prefix = "${var.project_short}-lb"
  #   enabled       = true
  # }

  tags {
    Name        = "${var.project}-elb"
    Environment = "${var.project_environment}"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_launch_configuration" "web" {
  # Either omit the Launch Configuration name attribute, or specify a partial name with name_prefix
  name_prefix = "${var.project}-lc-"

  instance_type = "m5.large"

  image_id = "${var.aws_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  security_groups = ["${aws_security_group.default.id}"]

  lifecycle {
    create_before_destroy = true
  }

  enable_monitoring = true
}

resource "aws_autoscaling_group" "web_asg" {
  name = "${var.project}-asg-${aws_launch_configuration.web.name}"

  launch_configuration = "${aws_launch_configuration.web.name}"

  min_size = 1

  max_size = 2

  min_elb_capacity = 1

  load_balancers = ["${aws_elb.web.id}"]

  vpc_zone_identifier = ["${aws_subnet.default.id}"]

  health_check_grace_period = 90

  health_check_type = "ELB"

  lifecycle {
    create_before_destroy = true
  }
}
