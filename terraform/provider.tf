terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
        helm = {
            source  = "hashicorp/helm"
            version = "~> 2.12"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.24"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}
