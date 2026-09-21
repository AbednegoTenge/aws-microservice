

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "microservice-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "microservice-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "microservice-public-rt"
  }
}


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "microservice-public-subnet"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "microservice-public-subnet-2"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat.id
  tags = {
    Name = "Nat-Gateway"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "microservice-private1-rt"
  }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "microservice-private2-rt"
  }
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

resource "aws_security_group" "alb" {
  name_prefix = "sg_alb"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_alb"
  }
}

resource "aws_security_group" "orders" {
  name_prefix = "sg_orders"
  description = "Security group for Orders ECS service"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_orders"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_orders" {
  security_group_id            = aws_security_group.orders.id
  referenced_security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 3003
  to_port     = 3003

  description = "Allow ALB to reach Orders service"
}

resource "aws_security_group" "products" {
  name_prefix = "sg_products"
  description = "Security group for Products ECS service"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_products"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_products" {
  security_group_id            = aws_security_group.products.id
  referenced_security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 3001
  to_port     = 3001

  description = "Allow ALB to reach Products service"
}


resource "aws_security_group" "inventory" {
  name_prefix = "sg_inventory"
  description = "Security group for Inventory ECS service"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_inventory"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_inventory" {
  security_group_id            = aws_security_group.inventory.id
  referenced_security_group_id = aws_security_group.alb.id

  ip_protocol = "tcp"
  from_port   = 3002
  to_port     = 3002

  description = "Allow ALB to reach Inventory service"
}

resource "aws_vpc_security_group_ingress_rule" "orders_to_inventory" {
  security_group_id            = aws_security_group.inventory.id
  referenced_security_group_id = aws_security_group.orders.id

  ip_protocol = "tcp"
  from_port   = 3002
  to_port     = 3002

  description = "Allow Orders to reach Inventory service"
}