region = "us-east-1"

vpc_cidr_block = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

ami_id        = "ami-0b6d9d3d33ba97d99"
instance_type = "t3.large"
key_name      = "hostar-key"

cluster_name       = "hotstar-eks"
kubernetes_version = "1.33"

eks_instance_types = ["t3.medium"]

desired_size = 1
min_size     = 1
max_size     = 2
