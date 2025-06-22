variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository."
  type        = string
  default     = "devops-project-l2"
}

variable "jenkins_instance_type" {
  description = "The EC2 instance type for the Jenkins server."
  type        = string
  default     = "t2.medium"
}

variable "tools_instance_type" {
  description = "The EC2 instance type for the Tools server (SonarQube, Trivy)."
  type        = string
  default     = "t3.large"
}

variable "monitoring_instance_type" {
  description = "The EC2 instance type for the Monitoring server (Prometheus, Grafana)."
  type        = string
  default     = "t3.medium"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "devops-project-cluster"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
} 