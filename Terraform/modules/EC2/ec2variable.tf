variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the EC2 instance"
}

variable "key_name" {
  type        = string
  description = "Key pair name for the EC2 instance"
}

variable "security_group_id" {
  type = string
}

