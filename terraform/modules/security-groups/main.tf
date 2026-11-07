terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "alb-${var.environment}-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "alb-${var.environment}-sg" }
  )
}

# ALB inbound: HTTPS from internet
resource "aws_security_group_rule" "alb_inbound_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
}

# ALB inbound: HTTP from internet
resource "aws_security_group_rule" "alb_inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet (redirect to HTTPS)"
}

# ALB outbound: to EKS nodes (default app port 8080)
resource "aws_security_group_rule" "alb_to_eks" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Forward to EKS pods"
}

# EKS Nodes Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "eks-node-${var.environment}-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "eks-node-${var.environment}-sg" }
  )
}

# EKS nodes inbound: from ALB on application port only
resource "aws_security_group_rule" "eks_inbound_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Application traffic from ALB to EKS nodes"
}

# EKS nodes inbound: Kubernetes control plane / intra-node needs limited TCP range
resource "aws_security_group_rule" "eks_inbound_self" {
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Node-to-node and kubelet communication within the node group"
}

# EKS nodes outbound: to RDS
resource "aws_security_group_rule" "eks_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "To RDS PostgreSQL"
}

# EKS nodes outbound: HTTPS to internet (for ECR, AWS APIs, etc.)
resource "aws_security_group_rule" "eks_outbound_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes.id
  description       = "HTTPS to AWS APIs and upstream registries via NAT"
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "rds-${var.environment}-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "rds-${var.environment}-sg" }
  )
}

# RDS inbound: from EKS nodes only
resource "aws_security_group_rule" "rds_inbound_from_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.rds.id
  description              = "From EKS nodes"
}

# RDS outbound: deny all (RDS only receives, doesn't initiate)
resource "aws_security_group_rule" "rds_outbound_deny" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["127.0.0.1/32"]
  security_group_id = aws_security_group.rds.id
  description       = "Deny all outbound"
}
