# Authentication info
variable "aws_access_key"{}
variable "aws_secret_key"{}
variable "aws_token"{}

# New Variable
variable "aws_ami"{}
variable "instance_type"{}
variable "key_name"{ default ="TerraformTest"}
#variable "instance_count" {}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    token = "${var.aws_token}"
    region = "eu-west-2"
}

# Virtual private cloud

resource "aws_vpc" "MainVpc" {
    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
        Name = "TerraformVPCTest"
    }
}

# Creating a public Subnet and assigning it to the correct VPC

resource "aws_subnet" "MainSubnet"{
    vpc_id = "${aws_vpc.MainVpc.id}"
    cidr_block       = "10.0.0.0/24"
     availability_zone = "eu-west-2a"

    tags{
        Name = "TerraformSubnetTest"
    }
}


# creating internet gateway and assigning it to the VPC

resource "aws_internet_gateway" "MainIG" {
    vpc_id = "${aws_vpc.MainVpc.id}"

    tags = {
        Name = "TerrformInternetGatewayTest"
    }
}


# Define the route table
resource "aws_route_table" "MainPublicRoute" {
  vpc_id = "${aws_vpc.MainVpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.MainIG.id}"
  }

  tags {
    Name = "Public Subnet RT"
  }
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "MainAssignPublicSubnet" {
  subnet_id = "${aws_subnet.MainSubnet.id}"
  route_table_id = "${aws_route_table.MainPublicRoute.id}"
}


# creating security group and assigning it to the correct VPC

resource "aws_security_group" "MainSG" {
    name        = "TerraformIG"
    description = "Allow all inbound and Outbound traffic"
    vpc_id = "${aws_vpc.MainVpc.id}"

        # setting the inbound rule to open for testing purposes
        ingress {
            from_port   = 0
            to_port     = 65535
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
        # setting the outbound rule to open for testing purposes
        egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
        Name = "TerraformSecurityGrouptest"
    }
}


# creating aws ec2  instance and assigning them to the correct subnet and SG

resource "aws_instance" "MainEC1"{

    ami = "${var.aws_ami}"
    instance_type = "${var.instance_type}"

    vpc_security_group_ids  = ["${aws_security_group.MainSG.id}"]
    key_name = "${var.key_name}"
    subnet_id ="${aws_subnet.MainSubnet.id}"
    #count = "${var.instance_count}"
    associate_public_ip_address= "true"

    provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apache2",
        ]

            connection {
                type        = "ssh"
                user        = "ubuntu"
                private_key = "${file("TerraformTest.pem")}"
                agent       = true
                timeout     = "1m"
        }
    }


    tags {
        Name ="TerraformInstanceTest1"
        Owner ="Shahin"
    }
}


#creating aws ec2-2  and assigning them to the correct subnet and SG

resource "aws_instance" "EC2_INSTANCE"{

    ami = "${var.aws_ami}"
    instance_type = "${var.instance_type}"

    vpc_security_group_ids  = ["${aws_security_group.MainSG.id}"]
    key_name = "${var.key_name}"
    subnet_id ="${aws_subnet.MainSubnet.id}"
    #count = "${var.instance_count}"
    associate_public_ip_address= "true"

    provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apache2",
        ]

            connection {
                type        = "ssh"
                user        = "ubuntu"
                private_key = "${file("TerraformTest.pem")}"
                agent       = true
                timeout     = "1m"
        }
    }

    tags {
        Name ="TerraformInstanceTest2"
        Owner ="Shahin"
    }
}

#3 creating aws ec2 instance and assigning them to the correct subnet and SG

resource "aws_instance" "MainEC3"{

    ami = "${var.aws_ami}"
    instance_type = "${var.instance_type}"
    vpc_security_group_ids  = ["${aws_security_group.MainSG.id}"]
    key_name = "${var.key_name}"
    subnet_id ="${aws_subnet.MainSubnet.id}"
    #count = "${var.instance_count}"
    associate_public_ip_address= "true"

    provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apache2",
        ]

            connection {
                type        = "ssh"
                user        = "ubuntu"
                private_key = "${file("TerraformTest.pem")}"
                agent       = true
                timeout     = "1m"
        }
    }
    tags {
        Name ="TerraformInstanceTest3"
        Owner ="Shahin"
    }
}


/*

# commenting out elastic IP

# Create elastic Ip addresss
resource "aws_eip" "eip1"{
instance = "${aws_instance.MainEC1.id}"
}

# Create elastic Ip addresss
resource "aws_eip" "eip2"{
instance = "${aws_instance.EC2_INSTANCE.id}"
}

# Create elastic Ip addresss
resource "aws_eip" "eip3"{
instance = "${aws_instance.MainEC3.id}"
}

*/

# Creating a Load Balancer for the ec2 instances
resource "aws_elb" "MainLB" {
  name               = "TerraFormLB"
 #availability_zones = ["eu-west-2a"]
  security_groups = ["${aws_security_group.MainSG.id}"]
  subnets =["${aws_subnet.MainSubnet.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances                   = ["${aws_instance.MainEC1.id}","${aws_instance.EC2_INSTANCE.id}","${aws_instance.MainEC3.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "TerraFormLB"
  }

 provisioner "local-exec"{
      command ="echo ${aws_elb.MainLB.dns_name} > loadBalancerAddress.txt"
  }
}

# Attaching the local teraform state to remote within a consul
terraform {
  backend "consul" {
    address = "localhost:8500" #consul installed locally
    path    = "Terraform/usecase1"
    lock    = false
  }
}

