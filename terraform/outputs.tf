output "app_url" {
  description = "Public application URL from the origin variable (domain or https URL). Use this — not a raw ephemeral IP."
  value       = var.origin
}

output "public_ip" {
  description = "Stable Elastic IP attached to the app host. Point DuckDNS (or other DNS) here."
  value       = aws_eip.app.public_ip
}

output "instance_id" {
  description = "EC2 instance ID for SSM administration."
  value       = aws_instance.app.id
}

output "ecr_repository_url" {
  description = "Push the application image to this ECR repository before bootstrapping the instance."
  value       = aws_ecr_repository.app.repository_url
}

output "database_endpoint" {
  description = "Private RDS endpoint."
  value       = aws_db_instance.database.address
}

output "database_secret_arn" {
  description = "Secrets Manager ARN containing the generated database credentials."
  value       = aws_secretsmanager_secret.database.arn
}
