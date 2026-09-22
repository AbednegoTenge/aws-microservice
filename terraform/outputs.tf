output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.microservice.repository_url
}

output "orders_db_secret_arn" {
  value = "${aws_db_instance.orders_db.master_user_secret[0].secret_arn}:username::"
}

output "orders_db_secret_password_arn" {
  value = "${aws_db_instance.orders_db.master_user_secret[0].secret_arn}:password::"
}

output "orders_db_endpoint" {
  value = aws_db_instance.orders_db.endpoint
}

output "orders_db_address" {
  value = aws_db_instance.orders_db.address
}

output "orders_db_port" {
  value = aws_db_instance.orders_db.port
}