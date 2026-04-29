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

    backend "s3" {
        bucket         = "voting-app-tfstate-erotonin"
        key            = "terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "voting-app-terraform-locks"
        encrypt        = true
    }
}

provider "aws" {
    region = var.aws_region
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.main.token
}
