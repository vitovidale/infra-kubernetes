provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "existing_vpc" {
  id = "vpc-035823898b0432060"
}

data "aws_subnet" "existing_subnet_1" {
  id = "subnet-0e8a9c57e24921ad2"
}

data "aws_subnet" "existing_subnet_2" {
  id = "subnet-054f5e7046e524dc7"
}

data "aws_iam_role" "existing_eks_cluster_role" {
  name = "eks-cluster-role"
}

data "aws_iam_role" "existing_eks_node_group_role" {
  name = "eks-node-group-role"
}

data "aws_eks_cluster" "existing_cluster" {
  name = "pollos-hermanos"
}

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

# ✅ Create a New Security Group for Worker Nodes
resource "aws_security_group" "eks_nodes_sg" {
  vpc_id = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    self        = true
    description = "Allow nodes to communicate with each other"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow worker nodes to communicate with EKS control plane"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow nodes outbound access"
  }

  tags = {
    Name = "eks-nodes-security-group"
  }
}

data "aws_eks_node_group" "existing_node_group" {
  cluster_name    = "pollos-hermanos"
  node_group_name = "fastfood-nodes"
}

resource "aws_eks_node_group" "fastfood_nodes" {
  count = length(data.aws_eks_node_group.existing_node_group.id) > 0 ? 0 : 1

  cluster_name    = "pollos-hermanos"
  node_group_name = "fastfood-nodes"
  node_role_arn   = data.aws_iam_role.existing_eks_node_group_role.arn
  subnet_ids      = [
    data.aws_subnet.existing_subnet_1.id,
    data.aws_subnet.existing_subnet_2.id
  ]

  # ✅ Attach worker nodes to the security group
  remote_access {
    ec2_ssh_key               = "eks-key-pair"
    source_security_group_ids = [aws_security_group.eks_nodes_sg.id]
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}
