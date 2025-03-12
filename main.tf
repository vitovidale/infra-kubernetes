# Provider AWS
provider "aws" {
  region = "us-east-1"
}

# ✅ **Use a Specific VPC ID**
data "aws_vpc" "existing_vpc" {
  id = "vpc-058954d5c60526128"  # <-- Replace with your actual VPC ID
}

# ✅ **Use Specific Subnet IDs**
data "aws_subnet" "existing_subnet_1" {
  id = "subnet-0e8a9c57e24921ad2"  # <-- Replace with your actual Subnet ID for us-east-1a
}

data "aws_subnet" "existing_subnet_2" {
  id = "subnet-054f5e7046e524dc7"  # <-- Replace with your actual Subnet ID for us-east-1b
}

# ✅ Retrieve Existing IAM Role for EKS Cluster
data "aws_iam_role" "existing_eks_cluster_role" {
  name = "eks-cluster-role"
}

# ✅ Retrieve Existing IAM Role for EKS Node Group
data "aws_iam_role" "existing_eks_node_group_role" {
  name = "eks-node-group-role"
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
