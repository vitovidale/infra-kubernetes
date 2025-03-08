# Provider AWS
provider "aws" {
  region = "us-east-1"
}

# Criação da VPC para o EKS
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

# Subnets públicas
resource "aws_subnet" "eks_subnet_1" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "eks-subnet-1"
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "eks-subnet-2"
  }
}

# IAM Role para o EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role para os Nodes EC2 do EKS
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_container_registry_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Cluster EKS (comentado para ativar quando quiser provisionar)
# resource "aws_eks_cluster" "fastfood_cluster" {
#   name     = "pollos-hermanos"
#   role_arn = aws_iam_role.eks_cluster_role.arn

#   vpc_config {
#     subnet_ids = [
#       aws_subnet.eks_subnet_1.id,
#       aws_subnet.eks_subnet_2.id
#     ]
#   }
# }

# Node Group para EKS (comentado para ativar quando quiser provisionar)
# resource "aws_eks_node_group" "fastfood_nodes" {
#   cluster_name    = aws_eks_cluster.fastfood_cluster.name
#   node_group_name = "fastfood-nodes"
#   node_role_arn   = aws_iam_role.eks_node_group_role.arn
#   subnet_ids      = [
#     aws_subnet.eks_subnet_1.id,
#     aws_subnet.eks_subnet_2.id
#   ]

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 1
#   }
# }
