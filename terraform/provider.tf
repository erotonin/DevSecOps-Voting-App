terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
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
