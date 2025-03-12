# Provider AWS
provider "aws" {
  region = "us-east-1"
}

# ✅ Retrieve Existing VPC Instead of Creating a New One
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["eks-vpc"]
  }
}

# ✅ Retrieve Existing IAM Role for EKS Cluster
data "aws_iam_role" "existing_eks_cluster_role" {
  name = "eks-cluster-role"
}

# ✅ Retrieve Existing IAM Role for EKS Node Group
data "aws_iam_role" "existing_eks_node_group_role" {
  name = "eks-node-group-role"
}

# ✅ Retrieve Existing Subnets
data "aws_subnet" "existing_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["eks-subnet-1"]
  }
}

data "aws_subnet" "existing_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["eks-subnet-2"]
  }
}

# ✅ Create the EKS Cluster Using Existing VPC & IAM Role
resource "aws_eks_cluster" "fastfood_cluster" {
  name     = "pollos-hermanos"
  role_arn = data.aws_iam_role.existing_eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.existing_subnet_1.id,
      data.aws_subnet.existing_subnet_2.id
    ]
    vpc_id = data.aws_vpc.existing_vpc.id
  }
}

# ✅ Create the EKS Node Group Using Existing IAM Role
resource "aws_eks_node_group" "fastfood_nodes" {
  cluster_name    = aws_eks_cluster.fastfood_cluster.name
  node_group_name = "fastfood-nodes"
  node_role_arn   = data.aws_iam_role.existing_eks_node_group_role.arn
  subnet_ids      = [
    data.aws_subnet.existing_subnet_1.id,
    data.aws_subnet.existing_subnet_2.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}
