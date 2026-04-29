output "repository_urls" {
  value = aws_ecr_repository.repo[*].repository_url
}
