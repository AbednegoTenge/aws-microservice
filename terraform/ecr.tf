

resource "aws_ecr_repository" "microservice" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

import {
  to = aws_ecr_repository.microservice
  id = "microservice"
}