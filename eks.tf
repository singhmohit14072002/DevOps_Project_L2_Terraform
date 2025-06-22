# Placeholder for EKS cluster configuration 

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

resource "aws_security_group_rule" "jenkins_to_eks" {
  description              = "Allow Jenkins to connect to the EKS API server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.jenkins_sg.id
}

// Data source to find the security group associated with the EKS node group
data "aws_security_groups" "eks_node_group_sgs" {
  tags = {
    "eks:cluster-name"   = var.cluster_name
    "eks:nodegroup-name" = "${var.cluster_name}-node-group"
  }
}

// Security group rule for node-exporter
resource "aws_security_group_rule" "monitoring_to_node_exporter" {
  description              = "Allow Monitoring server to scrape node-exporter"
  type                     = "ingress"
  from_port                = 31000
  to_port                  = 31000
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.monitoring_sg.id
}

// Security group rule for kube-state-metrics
resource "aws_security_group_rule" "monitoring_to_kube_state_metrics" {
  description              = "Allow Monitoring server to scrape kube-state-metrics"
  type                     = "ingress"
  from_port                = 32000
  to_port                  = 32000
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.monitoring_sg.id
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.private.*.id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "eks_node_group_role_arn" {
    description = "ARN of the EKS node group role"
    value = aws_iam_role.eks_node_group_role.arn
} 