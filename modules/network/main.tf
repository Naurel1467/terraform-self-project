#vpc
resource "aws_vpc" "vpc" {
    cidr_block = var.cidr_vpc
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    enable_classiclink = true
    tags = {
        Name = "myvpc"
    }
}

#security_groups_for public ec2


#public_subnet
resource "aws_subnet" "subnet_1" {
    cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = var.avail_zone[0]
    map_public_ip_on_launch = "true"


    tags = {
      "Name" = "sub-1"
    }
}

resource "aws_subnet" "subnet_2" {
    cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)}"
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = var.avail_zone[1]
    map_public_ip_on_launch = "true"
    

    tags = {
      "Name" = "sub-2"
    }
}

#private_subnet

#IGW_public
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"

    tags = {
      "Name" = "igw"
    }
  
}



#route-table_public
resource "aws_route_table" "route_public" {
    vpc_id = "${aws_vpc.vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
  tags = {
    "Name" = "route-public"
  }
}
#route-table private

#route table association public subnet
resource "aws_route_table_association" "route_assoc1" {
    subnet_id = "${aws_subnet.subnet_1.id}"
    route_table_id = "${aws_route_table.route_public.id}"  
}

resource "aws_route_table_association" "route_assoc2" {
    subnet_id = "${aws_subnet.subnet_2.id}"
    route_table_id = "${aws_route_table.route_public.id}"  
}

