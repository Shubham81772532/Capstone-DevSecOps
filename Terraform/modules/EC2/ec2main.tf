
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.52.0"
    }
  }
}

# ----------------------------
# EC2 Instance
# ----------------------------
resource "aws_instance" "hotstar_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 29
    volume_type = "gp3"
  }

  tags = {
    Name = "hotstar-ec2"
  }
}

# ----------------------------
# Elastic IP
# ----------------------------
resource "aws_eip" "hotstar_eip" {
  domain = "vpc"

  tags = {
    Name = "hotstar-eip"
  }

  depends_on = [
    aws_instance.hotstar_ec2
  ]
}

# ----------------------------
# Associate Elastic IP to EC2
# ----------------------------
resource "aws_eip_association" "hotstar_eip_association" {
  instance_id   = aws_instance.hotstar_ec2.id
  allocation_id = aws_eip.hotstar_eip.id
}