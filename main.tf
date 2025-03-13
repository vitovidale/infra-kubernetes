provider "aws" {
  region = "us-east-1"
}

# ✅ Use Existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-035823898b0432060"
}

# ✅ Use Existing Subnets Instead of Creating New Ones
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

# ✅ IAM Roles for EKS Cluster and Nodes
data "aws_iam_role" "existing_eks_cluster_role" {
  name = "eks-cluster-role"
}

data "aws_iam_role" "existing_eks_node_group_role" {
  name = "eks-node-group-role"
}

# ✅ Create EKS Cluster
resource "aws_eks_cluster" "fastfood_cluster" {
  name     = "pollos-hermanos"
  role_arn = data.aws_iam_role.existing_eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.existing_subnet_1.id,
      data.aws_subnet.existing_subnet_2.id
    ]
    endpoint_public_access = true
    endpoint_private_access = false
  }
}

# ✅ Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_nodes_sg" {
  vpc_id = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow nodes to communicate with each other"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow worker nodes to talk to EKS"
  }

  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Kubernetes pod-to-pod communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow nodes outbound access"
  }

  tags = {
    Name = "eks-nodes-security-group"
  }
}

# ✅ Create EKS Node Group (Worker Nodes)
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
