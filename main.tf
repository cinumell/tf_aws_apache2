terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
# !!Use your own access and secret keys!!
provider "aws"{
  region     = var.region
  access_key = "AKIA52LJEQNMWCTT53NX"
  secret_key = "GAqkjt7DUbpIYA8EJZ7XzsI5jdYDsK+Z44OpRS3x"
}

# Creating a VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block 
  tags = {
    "Name" = "Production ${var.main_vpc_name}"  # string interpolation
  }
}

# Creating a subnet in the VPC
resource "aws_subnet" "web"{
  vpc_id = aws_vpc.main.id
  cidr_block = var.web_subnet  
  availability_zone = var.subnet_zone
  tags = {
    "Name" = "Web subnet"
  }
}

# Creating an Intenet Gateway
resource "aws_internet_gateway" "my_web_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.main_vpc_name} IGW"
  }
}

#  Associating the IGW to the default RT
resource "aws_default_route_table" "main_vpc_default_rt" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"  # default route
    gateway_id = aws_internet_gateway.my_web_igw.id
  }
  tags = {
    "Name" = "my-default-rt"
  }
}

# Default Security Group
resource "aws_default_security_group" "default_sec_group" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    # the only source ip allowed
    cidr_blocks = ["188.25.221.50/32"]  # change it to your own public IP address
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "Default Security Group"
  }
}

# Creating a key-pair resource
resource "aws_key_pair" "production_key"{
  key_name = "prod_ssh_key"
  public_key = file(var.ssh_public_key)

  
}


## SOLUTION ###
# Create a data source to fetch the latest Ubuntu Server AMI in your region
data "aws_ami" "latest_ubuntu_server"{
  owners = ["099720109477"] # Canonical Account
  most_recent = true
  
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

# Spinning up an EC2 Instance
resource "aws_instance" "server" {
  # ami = "ami-01f87c43e618bf8f0" # Ubuntu Server
 
  # latest version of Ubuntu Server
  ami = data.aws_ami.latest_ubuntu_server.id
  # Connect using SSH: ssh -i ./prod_rsa ubuntu@UBUNTU_SERVER_PUBLIC_IP

  user_data = file("./entry_script.sh")
  
  instance_type = "t2.micro"

  subnet_id = aws_subnet.web.id
  vpc_security_group_ids = [aws_default_security_group.default_sec_group.id]
  associate_public_ip_address = true
  key_name = "prod_ssh_key"

  tags = {
    "Name" = "My EC2 Intance - Amazon Linux 2"
  }
}