provider "aws" {
    region = "${var.region}"
    profile = "default"
}

module "mymodule" {
  source = "./modules/network"
  cidr_vpc = var.cidr_vpc
  avail_zone =  var.avail_zone
  
}

### Creating Security Group for EC2
resource "aws_security_group" "instance" {
  vpc_id = "${module.mymodule.vpc.id}"
  name = "terraform-sg-for-instance"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #cidr_blocks = ["${var.my-ip}"]
    security_groups = [aws_security_group.elb-1.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #cidr_blocks = ["${var.my-ip}"]
    security_groups = [aws_security_group.elb-1.id]
  }
  tags = {
    "Name" = "custom-terraform-sg-for-instance"
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
  image_id      = data.aws_ami.ubuntu.id
  security_groups = ["${aws_security_group.instance.id}"]
  associate_public_ip_address = true
  instance_type = "t2.micro"
  key_name = "terra-key"
  user_data = "#!/bin/bash\napt-get update\napt-get -y install net-tools nginx\nMYIP = 'ifconfig | grep -E  '(inet addr:10)' | awk '{print $2}' | cut -d ':' -f 2'\necho 'hello team'\nthis is my ip : '$MYIP > /var/www/html/index.html'"
              
  lifecycle {
    create_before_destroy = false
  }
}
  
## Creating AutoScaling Group
resource "aws_autoscaling_group" "auto" {
  vpc_zone_identifier       = ["${module.mymodule.subnet-1.id}" , "${module.mymodule.subnet-2.id}"]
  count             = 1
  launch_configuration = "${aws_launch_configuration.lconf.id}"
  #subnet_id = ["${module.mymodule.subnet-1.id}" , "${module.mymodule.subnet-2.id}"]
  #availability_zones = ["${var.avail_zone[0]}", "${var.avail_zone[1]}" ]
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
resource "aws_security_group" "elb-1" {
  vpc_id = "${module.mymodule.vpc.id}"
  name = "terraform-example-elb-1"
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
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "my-elb-sg"
  }
}

### Creating ELB
resource "aws_elb" "elb" {
  
  name = "custom-elb"
  subnets = ["${module.mymodule.subnet-1.id}" , "${module.mymodule.subnet-2.id}"]
  security_groups = ["${aws_security_group.elb-1.id}"]
  #availability_zones = ["us-east-1a", "us-east-1b"]
  
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
  cross_zone_load_balancing   = true
  #idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    "Name" = "custom-elb"
  }

}
