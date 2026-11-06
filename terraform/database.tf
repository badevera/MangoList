resource "random_password" "database" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "database" {
  name       = "${var.project_name}-database"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "database" {
  identifier              = "${var.project_name}-${var.environment}"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  storage_type            = "gp3"
  db_name                 = "mango_list"
  username                = "mango_app"
  password                = random_password.database.result
  db_subnet_group_name    = aws_db_subnet_group.database.name
  vpc_security_group_ids  = [aws_security_group.database.id]
  publicly_accessible     = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
}

resource "aws_secretsmanager_secret" "database" {
  name                    = "${var.project_name}/${var.environment}/database"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = aws_db_instance.database.username
    password = random_password.database.result
    database = aws_db_instance.database.db_name
  })
}
