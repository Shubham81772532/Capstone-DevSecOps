variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "eks_instance_types" {
  type = list(string)
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_size" {
  type = number
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
