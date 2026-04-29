variable "aws_region" {
  default     = "us-east-1"
  description = "AWS Region to deploy resources"
}

variable "cluster_name" {
  default     = "voting-app-cluster"
  description = "EKS Cluster name"
}

variable "node_instance_type" {
  default     = "t3.medium"
  description = "EC2 instance type for EKS worker nodes"
}

variable "node_desired_size" {
  default     = 2
  description = "Desired number of worker nodes"
}

variable "node_max_size" {
  default     = 3
  description = "Maximum number of worker nodes"
}

variable "node_min_size" {
  default     = 1
  description = "Minimum number of worker nodes"
}

variable "github_repo" {
  default     = "erotonin/DevSecOps-Voting-App"
  description = "GitHub repository (owner/repo)"
}
