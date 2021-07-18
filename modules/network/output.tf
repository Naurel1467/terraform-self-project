output "vpc" {
    value = aws_vpc.vpc  
}

output "subnet-1" {
    value = aws_subnet.subnet_1
}

output "subnet-2" {
    value = aws_subnet.subnet_2
}