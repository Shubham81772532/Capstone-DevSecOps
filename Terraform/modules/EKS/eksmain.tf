module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

endpoint_public_access  = true
endpoint_private_access = false


  eks_managed_node_groups = {
    hotstar_nodes = {
      instance_types = var.eks_instance_types
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size

      labels = {
        Environment = "dev"
        App         = "hotstar"
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "hotstar-capstone"
  }
}
