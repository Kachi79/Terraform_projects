# Terraform_projects

Automating infrastructure with IAC using Terraform  

In this project we will provision an Aws infrastructure with 1 VPC, 6 subnets hosting 2 websites.

But we will first start with 2 public subnets.

# Create public subnets1
    resource "aws_subnet" "public1" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.0.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "eu-west-1a"

}

# Create public subnet2
    resource "aws_subnet" "public2" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.1.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "eu-west-1b"
}

Above is the configuration for the creation of 2 public subnets.