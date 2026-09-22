resource "aws_db_instance" "orders_db" {
  allocated_storage     = 10
  max_allocated_storage = 50
  storage_type          = "gp3"

  storage_encrypted = true

  db_name    = "orders_db"
  identifier = "orders-db"

  engine         = "postgres"
  engine_version = "17"

  instance_class = "db.t3.micro"
  multi_az       = true

  manage_master_user_password = true
  username                    = "admin"

  vpc_security_group_ids = [
    aws_security_group.orders_sg_db.id
  ]

  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false

  skip_final_snapshot = true
}


resource "aws_db_instance" "products_db" {
  allocated_storage     = 10
  max_allocated_storage = 50
  storage_type          = "gp3"

  storage_encrypted = true

  db_name    = "products_db"
  identifier = "products-db"

  engine         = "postgres"
  engine_version = "17"

  instance_class = "db.t3.micro"
  multi_az       = true

  manage_master_user_password = true
  username                    = "admin"

  vpc_security_group_ids = [
    aws_security_group.products_sg_db.id
  ]

  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false

  skip_final_snapshot = true
}


resource "aws_db_instance" "inventory_db" {
  allocated_storage     = 10
  max_allocated_storage = 50
  storage_type          = "gp3"

  storage_encrypted = true

  db_name    = "inventory_db"
  identifier = "inventory-db"

  engine         = "postgres"
  engine_version = "17"

  instance_class = "db.t3.micro"
  multi_az       = true

  manage_master_user_password = true
  username                    = "admin"

  vpc_security_group_ids = [
    aws_security_group.inventory_sg_db.id
  ]

  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false

  skip_final_snapshot = true
}