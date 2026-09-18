# ---------------------------------------------------------------------------
# EKS. The cluster the pipeline deploys to.
#
# Private subnets, private endpoint. The runner reaches the API through the
# VPC (in AWS: a runner instance in the VPC, or a VPN; locally: the emulator's
# Docker network). Everything the cluster pulls -- images from ECR, charts
# from the public Helm repos -- goes out through the NAT gateway.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.name}-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.name}-node"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster"
  description = "EKS control plane"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.name}-cluster" }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_vpc" {
  security_group_id = aws_security_group.cluster.id
  description       = "API server from inside the VPC (nodes, the runner)"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}

# The control plane only ever talks to things inside the VPC: kubelets and
# admission webhooks. The first IaC scan flagged 0.0.0.0/0 here as CRITICAL
# and it was right.
resource "aws_vpc_security_group_egress_rule" "cluster_to_vpc" {
  security_group_id = aws_security_group.cluster.id
  description       = "Kubelets (10250) and webhooks, inside the VPC only"
  from_port         = 1025
  to_port           = 65535
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  # No encryption_config: Kubernetes Secrets would be envelope-encrypted with
  # a KMS key at rest in etcd, and in a real account they should be. The
  # emulator accepts the block and discards it, which Terraform reads as
  # permanent drift. Accepted in .trivyignore.yaml with that reason.

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}
