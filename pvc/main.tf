resource "aws_vpc" "Main" {                # Creating VPC here
   cidr_block       = var.main_vpc_cidr #var.main_vpc_cidr     # Defining the CIDR block use 10.0.0.0/24 for demo
   instance_tenancy = "default"
   #name = "nagendra-pvc"
   tags = merge({
     "environment" = "UAT",
     "app" = "nagendra-app",
     "department" = "it",
     "Name"       = "nagendrapvc"
   })

   tags_all = merge({
     "Name"       = "nagendrapvc"
   })

   lifecycle {
    ignore_changes = [tags]
   }
   
 }
# Create Internet Gateway and attach it to VPC
 resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
    vpc_id =  aws_vpc.Main.id               # vpc_id will be generated after we create VPC

    tags = merge({
     "Name"       = "nagendra-internet-gateway"
   })

   tags_all = merge({
     "Name"       = "nagendra-internet-gateway"
   })
 }
 #Create a Public Subnets.
 resource "aws_subnet" "publicsubnets" {    # Creating Public Subnets
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnets}"        # CIDR block of public subnets
   map_public_ip_on_launch = true
   tags = merge({
     "Name"       = "nagendra-public-subnet"
   })

   tags_all = merge({
     "Name"       = "nagendra-public-subnet"
   })
 }
 #Create a Private Subnet                   # Creating Private Subnets
 resource "aws_subnet" "privatesubnets" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnets}"          # CIDR block of private subnets

   tags = merge({
     "Name"       = "nagendra-private-subnet"
   })

   tags_all = merge({
     "Name"       = "nagendra-private-subnet"
   })
 }
 #Route table for Public Subnet's
 resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
    vpc_id =  aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
     }

     
    tags = merge({
     "Name"       = "nagendra-public-rtable"
   })

   tags_all = merge({
     "Name"       = "nagendra-public-rtable"
   })
 }
 #Route table for Private Subnet's
 resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }

   tags = merge({
     "Name"       = "nagendra-private-rtable"
   })

   tags_all = merge({
     "Name"       = "nagendra-private-rtable"
   })

 }
 #Route table Association with Public Subnet's
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
 }
 #Route table Association with Private Subnet's
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.privatesubnets.id
    route_table_id = aws_route_table.PrivateRT.id

 }
 resource "aws_eip" "nateIP" {
   vpc   = true

   tags = merge({
     "Name"       = "nagendra-e-ip"
   })

   tags_all = merge({
     "Name"       = "nagendra-e-ip"
   })
 }
 #Creating the NAT Gateway using subnet_id and allocation_id
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnets.id

   tags = merge({
     "Name"       = "nagendra-netgateway"
   })

   tags_all = merge({
     "Name"       = "nagendra-netgateway"
   })
 }

resource "tls_private_key" basion_p_key  {
  algorithm = "RSA"
}


resource "aws_key_pair" "basion_key_pair" {
  key_name    = "basion_key_pair"
  public_key = tls_private_key.basion_p_key.public_key_openssh
  }

resource "local_file" "private_key_basiton" {
  depends_on = [
    tls_private_key.basion_p_key,
  ]
  content  = tls_private_key.basion_p_key.private_key_pem
  filename = "basiton.pem"
}

resource "aws_security_group" "instance_sg" {
  name        = "web auto scaling group security group"
  vpc_id      = "${aws_vpc.Main.id}"
# Inbound Rules
  # HTTPS access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "BASTION" {
  ami           = "ami-04fc979a55e14b094"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.publicsubnets.id
  security_groups = [aws_security_group.instance_sg.id]
  key_name = "basion_key_pair"
  tags = {
    Name = "ImageHost"
  }
}