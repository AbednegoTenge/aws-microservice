

resource "aws_cloudwatch_log_group" "orders" {
  name              = "/ecs/orders"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "products" {
  name              = "/ecs/products"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "inventory" {
  name              = "/ecs/inventory"
  retention_in_days = 7
}