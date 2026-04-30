resource "aws_ecr_repository" "repo" {
  count                = length(var.repo_names)
  name                 = var.repo_names[count.index]
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}
