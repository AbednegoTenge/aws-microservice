

resource "aws_lb" "alb" {
  name                       = "microservice-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [aws_subnet.public.id, aws_subnet.public2.id]
  enable_deletion_protection = true
  tags = {
    Name = "microservice-alb"
  }
}


resource "aws_lb_target_group" "orders" {
  name        = "orders-tg"
  port        = 3003
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/orders/health"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "products" {
  name        = "products-tg"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/products/health"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "inventory" {
  name        = "inventory-tg"
  port        = 3002
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/inventory/health"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.products.arn
  }
}

resource "aws_lb_listener_rule" "orders" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orders.arn
  }
  condition {
    path_pattern {
      values = [
        "/orders",
        "/orders*"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "products" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.products.arn
  }
  condition {
    path_pattern {
      values = [
        "/products",
        "/products*"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "inventory" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 300
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory.arn
  }
  condition {
    path_pattern {
      values = [
        "/inventory",
        "/inventory*"
      ]
    }
  }
}

