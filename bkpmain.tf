provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2-poc-deploy-cybersec"
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-poc-deploy-cybersec-sg"
  description = "Acesso SSH e HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "poc_instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3a.medium"
  key_name        = aws_key_pair.ec2_key.key_name
  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = "ec2-poc-deploy-cybersec"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "Hello from Terraform!" > /var/www/html/index.html
              EOF
}

resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = "ec2-poc-deploy-cybersec.pem"
}

output "instance_public_ip" {
  value = aws_instance.poc_instance.public_ip
}

output "instance_id" {
  value = aws_instance.poc_instance.id
}
