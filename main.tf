provider "aws" {
  region = "us-east-1"
}

# Use Existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-035823898b0432060"
}

# Use Existing Subnets
data "aws_subnet" "existing_subnet_1" {
  id = "subnet-0e8a9c57e24921ad2"
}

data "aws_subnet" "existing_subnet_2" {
  id = "subnet-054f5e7046e524dc7"
}

# Use Existing IAM Roles
data "aws_iam_role" "existing_eks_cluster_role" {
  name = "eks-cluster-role"
}

data "aws_iam_role" "existing_eks_node_group_role" {
  name = "eks-node-group-role"
}

# Check if EKS Cluster Exists
data "aws_eks_cluster" "existing_cluster" {
  name = "pollos-hermanos"
}

# Create EKS Cluster Only If It Doesn't Exist
resource "aws_eks_cluster" "fastfood_cluster" {
  count = length(data.aws_eks_cluster.existing_cluster.id) > 0 ? 0 : 1

  name     = "pollos-hermanos"
  role_arn = data.aws_iam_role.existing_eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.existing_subnet_1.id,
      data.aws_subnet.existing_subnet_2.id
    ]
  }
}

# Check for Existing Security Group
data "aws_security_group" "existing_eks_nodes_sg" {
  filter {
    name   = "group-name"
    values = ["eks-nodes-security-group"]
  }
}

# Create Security Group Only If Missing
resource "aws_security_group" "eks_nodes_sg" {
  count = length(data.aws_security_group.existing_eks_nodes_sg.id) > 0 ? 0 : 1

  vpc_id = data.aws_vpc.existing_vpc.id

  # Allow all communication between worker nodes
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow nodes to communicate with each other"
  }

  # Allow worker nodes to communicate with EKS control plane
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow worker nodes to talk to EKS"
  }

  # Allow pods to communicate within the cluster
  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Kubernetes pod-to-pod communication"
  }

  # Outbound rules allow full internet access
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

# Check If Node Group Exists
data "aws_eks_node_group" "existing_node_group" {
  cluster_name    = "pollos-hermanos"
  node_group_name = "fastfood-nodes"
}

# Create Node Group Only If Missing
resource "aws_eks_node_group" "fastfood_nodes" {
  count = length(data.aws_eks_node_group.existing_node_group.id) > 0 ? 0 : 1

  cluster_name    = "pollos-hermanos"
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
