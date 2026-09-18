output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "ecr_repository_url" {
  description = "Image repository. The pipeline pushes <url>:<commit sha>."
  value       = aws_ecr_repository.app.repository_url
}

output "reports_bucket" {
  value = aws_s3_bucket.reports.bucket
}

output "secret_names" {
  description = "Secrets Manager names the cluster's ExternalSecrets refer to."
  value = {
    app_api_key   = aws_secretsmanager_secret.app_api_key.name
    grafana_admin = aws_secretsmanager_secret.grafana_admin.name
    dast_token    = aws_secretsmanager_secret.dast_token.name
  }
}

output "vpc_id" {
  value = aws_vpc.this.id
}
