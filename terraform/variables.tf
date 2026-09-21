variable "aws_region" {
  default     = "us-east-1"
  description = "AWS region to deploy resources"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block address"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "microservice"
}
