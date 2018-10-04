# Specify the provider and access details
provider "aws" {
  version = "~> 1.28"
  region = "${var.aws_region}"
}

# Get ACM certificate for edx domain to be used
data "aws_acm_certificate" "edx" {
  domain   = "${var.edx_domain}"
  statuses = ["ISSUED"]
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

# A security group for the external elb server so it is accessible via the web
resource "aws_security_group" "edx-elb-sg" {
  name        = "${var.project}-sg-elb"
  description = "Used in the edx frontend elb server"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
# the instances over SSH
resource "aws_security_group" "edx-app-sg" {
  name        = "${var.project}-sg-edx-app"
  description = "Used in the edx backend services"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from vpc
  # common
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  # #lms
  # ingress {
  #   from_port   = 18000
  #   to_port     = 18000
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #insights
  # ingress {
  #   from_port   = 18110
  #   to_port     = 18110
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #discovery
  # ingress {
  #   from_port   = 18381
  #   to_port     = 18381
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #ecommerce
  # ingress {
  #   from_port   = 18130
  #   to_port     = 18130
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #analytics
  # ingress {
  #   from_port   = 18100
  #   to_port     = 18100
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #xqueue
  # ingress {
  #   from_port   = 18040
  #   to_port     = 18040
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #cms
  # ingress {
  #   from_port   = 18010
  #   to_port     = 18010
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #forum
  # ingress {
  #   from_port   = 14567
  #   to_port     = 14567
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #certs
  # ingress {
  #   from_port   = 18090
  #   to_port     = 18090
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }
  # #credentials
  # ingress {
  #   from_port   = 18150
  #   to_port     = 18150
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "edx-elb" {
  name_prefix     = "${var.project_short}-"
  internal = false

  security_groups = ["${aws_security_group.edx-elb-sg.id}"]  
  subnets = ["${aws_subnet.default.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.edx.arn}"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 6
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 20
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 120
  connection_draining         = true
  connection_draining_timeout = 120

  tags {
    Name = "${var.project}-elb"
    Domain = "${var.edx_domain}"
    Environment = "${var.project_environment}"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_launch_configuration" "edx-app" {
  # Either omit the Launch Configuration name attribute, or specify a partial name with name_prefix
  name_prefix = "${var.project}-lc-"

  instance_type = "${var.app_instance_type}"

  image_id = "${var.aws_app_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  security_groups = ["${aws_security_group.edx-app-sg.id}"]

  lifecycle {
    create_before_destroy = true
  }

  enable_monitoring = true
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 60
    delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name = "${var.project}-asg-${aws_launch_configuration.edx-app.name}"

  launch_configuration = "${aws_launch_configuration.edx-app.name}"

  min_size = 1

  max_size = 2

  min_elb_capacity = 1

  load_balancers = ["${aws_elb.edx-elb.id}"]

  vpc_zone_identifier = ["${aws_subnet.default.id}"]

  health_check_grace_period = 90

  health_check_type = "ELB"

  lifecycle {
    create_before_destroy = true
  }
}
