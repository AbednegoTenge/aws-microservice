terraform {
  backend "s3" {
    bucket       = "microservice-project-tfstate"
    key          = "ecs/microservice/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
