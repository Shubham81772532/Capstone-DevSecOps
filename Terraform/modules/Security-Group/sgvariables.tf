variable "vpc_id" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "sg_description" {
  type = string
}

variable "ssh_cidr" {
  type = list(string)
}
