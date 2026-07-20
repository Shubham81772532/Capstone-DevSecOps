variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name for subnet tags"
  type        = string
  default     = "hotstar-eks"
}
