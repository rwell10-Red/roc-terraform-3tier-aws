# =============================================================================
# Database Tier — RDS MySQL
# =============================================================================

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group-${local.suffix}"
  subnet_ids = [aws_subnet.private_db.id, aws_subnet.private_db_2.id]

  tags = {
    Name = "${local.name_prefix}-db-subnet-group-${local.suffix}"
  }
}

# -----------------------------------------------------------------------------
# RDS Instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier     = "${local.name_prefix}-db-${local.suffix}"
  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  port              = var.db_port

  username                            = var.db_username
  password                            = random_password.db_password.result
  iam_database_authentication_enabled = true

  publicly_accessible        = false
  storage_encrypted          = true
  kms_key_id                 = var.db_kms_key_id != "" ? var.db_kms_key_id : null
  auto_minor_version_upgrade = true

  backup_retention_period = var.db_backup_retention_period
  copy_tags_to_snapshot   = true
  deletion_protection     = true
  skip_final_snapshot     = true

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  tags = {
    Name = "${local.name_prefix}-db-${local.suffix}"
  }
}
