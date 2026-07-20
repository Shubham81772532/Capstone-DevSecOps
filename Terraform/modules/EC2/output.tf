output "instance_id" {
  value = aws_instance.hotstar_ec2.id
}

output "private_ip" {
  value = aws_instance.hotstar_ec2.private_ip
}

output "ec2_public_ip" {
  description = "Elastic IP of EC2"
  value       = aws_eip.hotstar_eip.public_ip
}