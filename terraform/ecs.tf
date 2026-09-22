data "aws_ecr_image" "orders" {
  repository_name = aws_ecr_repository.microservice.name
  image_tag       = "orders-latest"
}

data "aws_ecr_image" "products" {
  repository_name = aws_ecr_repository.microservice.name
  image_tag       = "products-latest"
}

data "aws_ecr_image" "inventory" {
  repository_name = aws_ecr_repository.microservice.name
  image_tag       = "inventory-latest"
}

data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
}

resource "aws_iam_role" "orders_task_role" {
  name = "ecs-orders-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "products_task_role" {
  name = "ecs-products-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "inventory_task_role" {
  name = "ecs-inventory-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = data.aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "ecs-execution-secrets"
  role = data.aws_iam_role.ecs_task_execution.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_db_instance.orders_db.master_user_secret[0].secret_arn,
          aws_db_instance.products_db.master_user_secret[0].secret_arn,
          aws_db_instance.inventory_db.master_user_secret[0].secret_arn
        ]
      }
    ]
  })
}


resource "aws_ecs_task_definition" "orders" {
  family                   = "orders"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.orders_task_role.arn
  depends_on               = [aws_cloudwatch_log_group.orders, aws_iam_role_policy_attachment.ecs_task_execution]
  container_definitions = jsonencode([
    {
      name  = "orders"
      image = "${aws_ecr_repository.microservice.repository_url}@${data.aws_ecr_image.orders.image_digest}"
      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = "${aws_db_instance.orders_db.master_user_secret[0].secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_db_instance.orders_db.master_user_secret[0].secret_arn}:password::"
        }
      ]
      cpu       = 10
      memory    = 512
      essential = true
      environment = [
        { name = "INVENTORY_URL", value = "http://inventory:3002" },
        { name = "DB_HOST", value = aws_db_instance.orders_db.address },
        { name = "DB_PORT", value = tostring(aws_db_instance.orders_db.port) },
        { name = "DB_NAME", value = aws_db_instance.orders_db.db_name }
      ]
      portMappings = [
        {
          name          = "orders-port"
          containerPort = 3003
          hostPort      = 3003
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = "/ecs/orders"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "products" {
  family                   = "products"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.products_task_role.arn
  depends_on               = [aws_cloudwatch_log_group.products, aws_iam_role_policy_attachment.ecs_task_execution]
  container_definitions = jsonencode([
    {
      name      = "products"
      image     = "${aws_ecr_repository.microservice.repository_url}@${data.aws_ecr_image.products.image_digest}"
      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = "${aws_db_instance.products_db.master_user_secret[0].secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_db_instance.products_db.master_user_secret[0].secret_arn}:password::"
        }
      ]
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "DB_HOST", value = aws_db_instance.products_db.address },
        { name = "DB_PORT", value = tostring(aws_db_instance.products_db.port) },
        { name = "DB_NAME", value = aws_db_instance.products_db.db_name }
      ]
      portMappings = [
        {
          name          = "products"
          containerPort = 3001
          hostPort      = 3001
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = "/ecs/products"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "inventory" {
  family                   = "inventory"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.inventory_task_role.arn
  depends_on               = [aws_cloudwatch_log_group.inventory, aws_iam_role_policy_attachment.ecs_task_execution]
  container_definitions = jsonencode([
    {
      name      = "inventory"
      image     = "${aws_ecr_repository.microservice.repository_url}@${data.aws_ecr_image.inventory.image_digest}"
      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = "${aws_db_instance.inventory_db.master_user_secret[0].secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_db_instance.inventory_db.master_user_secret[0].secret_arn}:password::"
        }
      ]
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        { name = "DB_HOST", value = aws_db_instance.inventory_db.address },
        { name = "DB_PORT", value = tostring(aws_db_instance.inventory_db.port) },
        { name = "DB_NAME", value = aws_db_instance.inventory_db.db_name }
      ]
      portMappings = [
        {
          name          = "inventory-port"
          containerPort = 3002
          hostPort      = 3002
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = "/ecs/inventory"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_cluster" "main" {
  name = "microservice-project"
}

resource "aws_ecs_service" "orders" {
  name            = "orders_service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.orders.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.orders.arn
    container_name   = "orders"
    container_port   = 3003
  }
  network_configuration {
    subnets          = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups  = [aws_security_group.orders.id]
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.microservices.arn
    service {
      port_name      = "orders-port"
      discovery_name = "orders"

      client_alias {
        dns_name = "orders"
        port     = 3003
      }
    }
  }
}

resource "aws_ecs_service" "products" {
  name            = "products_service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.products.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.products.arn
    container_name   = "products"
    container_port   = 3001
  }
  network_configuration {
    subnets          = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups  = [aws_security_group.products.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "inventory" {
  name            = "inventory_service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.inventory.arn
    container_name   = "inventory"
    container_port   = 3002
  }
  network_configuration {
    subnets          = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups  = [aws_security_group.inventory.id]
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.microservices.arn
    service {
      port_name      = "inventory-port"
      discovery_name = "inventory"

      client_alias {
        dns_name = "inventory"
        port     = 3002
      }
    }
  }
}


resource "aws_service_discovery_http_namespace" "microservices" {
  name = "microservices"
}