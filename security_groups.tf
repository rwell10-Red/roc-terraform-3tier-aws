# =============================================================================
# Security Groups
# =============================================================================

# -----------------------------------------------------------------------------
# Front-End / ALB Security Group (shared by ALB and front-end EC2 instances)
# -----------------------------------------------------------------------------

resource "aws_security_group" "frontend" {
  name        = "${local.name_prefix}-frontend-sg-${local.suffix}"
  description = "Security group for ALB and front-end EC2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-frontend-sg-${local.suffix}"
  }
}

resource "aws_security_group_rule" "frontend_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Allow HTTP from anywhere"
}

resource "aws_security_group_rule" "frontend_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Allow HTTPS from anywhere"
}

resource "aws_security_group_rule" "frontend_ingress_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eice.id
  security_group_id        = aws_security_group.frontend.id
  description              = "Allow SSH from EICE SG"
}

resource "aws_security_group_rule" "frontend_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Allow HTTPS outbound (updates, APIs)"
}

resource "aws_security_group_rule" "frontend_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
  description       = "Allow HTTP outbound (package repos)"
}

resource "aws_security_group_rule" "frontend_egress_to_backend" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.frontend.id
  description              = "Allow outbound to backend app port"
}

# -----------------------------------------------------------------------------
# Back-End Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "backend" {
  name        = "${local.name_prefix}-backend-sg-${local.suffix}"
  description = "Security group for back-end EC2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-backend-sg-${local.suffix}"
  }
}

resource "aws_security_group_rule" "backend_ingress_app" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = aws_security_group.backend.id
  description              = "Allow app port from ALB/front-end SG"
}

resource "aws_security_group_rule" "backend_ingress_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eice.id
  security_group_id        = aws_security_group.backend.id
  description              = "Allow SSH from EICE SG"
}

resource "aws_security_group_rule" "backend_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
  description       = "Allow HTTPS outbound (updates, APIs)"
}

resource "aws_security_group_rule" "backend_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
  description       = "Allow HTTP outbound (package repos)"
}

resource "aws_security_group_rule" "backend_egress_to_db" {
  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database.id
  security_group_id        = aws_security_group.backend.id
  description              = "Allow outbound to database port"
}

# -----------------------------------------------------------------------------
# Database Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg-${local.suffix}"
  description = "Security group for RDS database instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-database-sg-${local.suffix}"
  }
}

resource "aws_security_group_rule" "database_ingress_from_backend" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.database.id
  description              = "Allow database port from back-end SG"
}

# NOTE: No explicit egress rules — relies on stateful return traffic only

# -----------------------------------------------------------------------------
# EC2 Instance Connect Endpoint (EICE) Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "eice" {
  name        = "${local.name_prefix}-eice-sg-${local.suffix}"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-eice-sg-${local.suffix}"
  }
}

resource "aws_security_group_rule" "eice_egress_ssh_backend" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.private_app_subnet_cidr]
  security_group_id = aws_security_group.eice.id
  description       = "Allow outbound SSH to private app subnet (backend)"
}

resource "aws_security_group_rule" "eice_egress_ssh_frontend" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.public_subnet_cidr]
  security_group_id = aws_security_group.eice.id
  description       = "Allow outbound SSH to public subnet (frontend)"
}
