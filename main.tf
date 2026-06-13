# main.tf - Infrastructure as Code avec Terraform
# Déploiement d'une instance AWS EC2 avec Nginx

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Groupe de sécurité : autoriser HTTP (80) et SSH (22)
resource "aws_security_group" "web_sg" {
  name        = "devops-web-sg"
  description = "Autoriser HTTP et SSH"

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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps-SG"
  }
}

# Instance EC2 avec Nginx installé automatiquement
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 (us-east-1)
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name        = "DevOps-Server"
    Environment = "TP"
  }

  # Script d'initialisation : installe Nginx au démarrage
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Serveur DevOps UCAD déployé avec Terraform !</h1>" > /var/www/html/index.html
  EOF
}

# Afficher l'IP publique après déploiement
output "public_ip" {
  description = "Adresse IP publique du serveur"
  value       = aws_instance.web.public_ip
}

output "url" {
  description = "URL d'accès au serveur"
  value       = "http://${aws_instance.web.public_ip}"
}
