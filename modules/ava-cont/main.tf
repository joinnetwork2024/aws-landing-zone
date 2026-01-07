resource "aws_instance" "aviatrix_controller" {
  ami           = var.aviatrix_ami_id  # e.g., "ami-0123456789abcdef0" from Marketplace
  instance_type = "t3.large"
  subnet_id     = var.subnet_id  # From existing networking VPC in central account
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.aviatrix_sg.id]

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "Aviatrix-Controller"
  }

  user_data = <<-EOT
  #!/bin/bash
  # Initial setup script for Aviatrix Controller (customize per docs)
  EOT
}

resource "aws_eip" "controller_eip" {
  instance = aws_instance.aviatrix_controller.id
  tags = {
    Name = "Aviatrix-Controller-EIP"
  }
}

resource "aws_security_group" "aviatrix_sg" {
  name        = "aviatrix-controller-sg"
  description = "Security group for Aviatrix Controller"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["8.8.8.8/32"]  # Restrict to trusted IPs in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}