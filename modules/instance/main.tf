#key_pairs
resource "aws_key_pair" "terr-key" {
  key_name = "terra-key"
  public_key = "${file(C/Users/ravit/Downloads/terra-key)}"
}


#public instance
resource "aws_instance" "public-inst" { 
    count = length(var.counter)   
    ami = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    key_name = "terra-key"
    subnet_id = "${aws_subnet.subnet_public.id}"
    vpc_security_group_ids = ["${aws_security_group.public_sg.id}"]

    tags = {
        #"Name" = "${format("web-%03d", count.index + 1)}"
       # Name = "${var.counter[count.index]}${count.index + 1}" #raviteja1 laxmi2 ammayi3  
       Name = "${element(var.counter, count.index)}${count.index + 1}"  #raviteja1 laxmi2 ammayi3 
    }
  
}

#private_instance
/*resource "aws_instance" "private-inst" {
    ami= "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    key_name = "terra-key"
    subnet_id = "${aws_subnet.subnet_private.id}" 
    vpc_security_group_ids = [ "${aws_security_group.private_sg.id}" ]
}

output "instance_pub" {
  value = aws_instance.private-inst.private_ip
}*/