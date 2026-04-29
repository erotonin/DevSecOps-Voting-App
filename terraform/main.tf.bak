module "networking" {
  source          = "./modules/networking"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = var.cluster_name
  subnet_ids         = module.networking.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_max_size      = var.node_max_size
  node_min_size      = var.node_min_size
}

module "ecr" {
  source     = "./modules/ecr"
  repo_names = ["voting-app-vote", "voting-app-result", "voting-app-worker"]
}
