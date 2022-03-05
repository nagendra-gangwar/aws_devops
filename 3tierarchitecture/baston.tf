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

resource "aws_security_group" "only_ssh_bositon" {
  depends_on=[aws_subnet.public_subnet[0]]
  name        = "only_ssh_bositon"
  vpc_id      =  aws_vpc.AWSVPC.id

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

  tags = {
    Name = "only_ssh_bositon"
  }
}

resource "aws_instance" "BASTION" {
  ami           = "ami-04fc979a55e14b094"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [ aws_security_group.only_ssh_bositon.id ]
  key_name = "basion_key_pair"

  tags = {
    Name = "bastionhost"
    }
}