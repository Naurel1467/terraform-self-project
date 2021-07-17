provider "aws" {
    region = "${var.region}"
    profile = "default"
}

### Creating Security Group for EC2
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["${var.my-ip}"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my-ip}"]
  }
}

data "aws_availability_zones" "all" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "lconf" {
  name          = "web_config"
  image_id      = "${data.aws_ami.ubuntu.id}"
  security_groups = ["${aws_security_group.instance.id}"]
  instance_type = "t2.micro"
  key_name = "terra-key"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}
  
## Creating AutoScaling Group
resource "aws_autoscaling_group" "auto" {
  count             = 1
  launch_configuration = "${aws_launch_configuration.lconf.id}"
  availability_zones = ["us-east-1a", "us-east-1b" ]
  min_size = 2
  max_size = 4
  load_balancers = ["${aws_elb.elb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "new-one_${count.index + 1}"   #newly created instacnes wil be named like this
    propagate_at_launch = true
  }
}

## Security Group for ELB
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### Creating ELB
resource "aws_elb" "elb" {
  name = "raviteja-elb"
  security_groups = ["${aws_security_group.elb.id}"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }

  

  /*instances                   = [aws_instance.foo.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400*/

}
