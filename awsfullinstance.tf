terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


variable "vpcname" {
type = string
default = "ab-myvpc1"
}

variable "myregion" {
type = string
default = "us-east-1"
}

variable "aminame" {
type = map
default = {
  us-west-2 = "ami-098e42ae54c764c35"
  us-east-1 = "ami-0cff7528ff583bf9a"
 eu-west-1 = "ami-0d71ea30463e0ff8d"
}
}


provider "aws" {
region = "us-east-1"
access_key = "AKIA2RLIAWXT6LCGKWX3"
  secret_key = "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"
}

resource "aws_vpc" "ab_myvpc1" {
 cidr_block = "10.0.0.0/16"
 tags = {
   Name = "testing"
}
}
resource "aws_internet_gateway" "ab_myigw" {
 vpc_id = aws_vpc.ab_myvpc1.id
 tags = { 
  Name = "myigw"
}
}

resource "aws_subnet" "ab_mypub1" { 
  vpc_id = aws_vpc.ab_myvpc1.id
  map_public_ip_on_launch = true
  cidr_block = "10.0.10.0/24"
  tags = {
   Name = "pubsub"
 }
}
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.ab_myvpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ab_myigw.id
  }
}

resource "aws_route_table_association" "ab_associate" {
  subnet_id      = aws_subnet.ab_mypub1.id
  route_table_id = aws_route_table.example.id
}
resource "aws_security_group" "ab_sg" {
  name        = "allow_ssh"
  vpc_id      = aws_vpc.ab_myvpc1.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}


#Launching APACHE
#---
resource "aws_instance" "ab_foo1" {
  ami           = "${var.aminame["${var.myregion}"]}"
  instance_type = "t2.micro"
  #security_groups = [aws_security_group.ab_sg.id]
  vpc_security_group_ids = ["${aws_security_group.ab_sg.id}"]
  user_data = <<-EOF
    #!/bin/bash
    echo "install apache"
    sudo yum install httpd -y
    echo "hello from EC2" > /var/www/html/index.html
    sudo systemctl restart httpd
    sudo systemctl enable httpd
  EOF
  key_name = "test"
  subnet_id = aws_subnet.ab_mypub1.id
}
