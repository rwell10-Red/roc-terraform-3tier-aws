# =============================================================================
# IAM Roles and Instance Profiles
# =============================================================================

# -----------------------------------------------------------------------------
# EC2 Trust Policy (shared by both roles)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# -----------------------------------------------------------------------------
# Front-End IAM Role and Instance Profile
# -----------------------------------------------------------------------------

resource "aws_iam_role" "frontend" {
  name               = "${local.name_prefix}-frontend-role-${local.suffix}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "frontend" {
  name = "${local.name_prefix}-frontend-profile-${local.suffix}"
  role = aws_iam_role.frontend.name
}

# -----------------------------------------------------------------------------
# Back-End IAM Role and Instance Profile
# -----------------------------------------------------------------------------

resource "aws_iam_role" "backend" {
  name               = "${local.name_prefix}-backend-role-${local.suffix}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "backend" {
  name = "${local.name_prefix}-backend-profile-${local.suffix}"
  role = aws_iam_role.backend.name
}

# -----------------------------------------------------------------------------
# IAM DB Auth Policy for Back-End Role
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "rds_iam_auth" {
  statement {
    effect  = "Allow"
    actions = ["rds-db:connect"]

    resources = [
      "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.main.resource_id}/${var.db_username}"
    ]
  }
}

resource "aws_iam_policy" "rds_iam_auth" {
  name   = "${local.name_prefix}-rds-iam-auth-${local.suffix}"
  policy = data.aws_iam_policy_document.rds_iam_auth.json
}

resource "aws_iam_role_policy_attachment" "backend_rds_auth" {
  role       = aws_iam_role.backend.name
  policy_arn = aws_iam_policy.rds_iam_auth.arn
}

# -----------------------------------------------------------------------------
# Additional Policy Attachments for Back-End Role
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "backend_additional" {
  count      = length(var.be_additional_policy_arns)
  role       = aws_iam_role.backend.name
  policy_arn = var.be_additional_policy_arns[count.index]
}

# -----------------------------------------------------------------------------
# RDS Enhanced Monitoring Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring" {
  name               = "${local.name_prefix}-rds-monitoring-role-${local.suffix}"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json
}

data "aws_iam_policy_document" "rds_monitoring_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------------------------------------------------------
# VPC Flow Log IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "vpc_flow_log" {
  name               = "${local.name_prefix}-vpc-flow-log-role-${local.suffix}"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_assume_role.json
}

data "aws_iam_policy_document" "vpc_flow_log_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vpc_flow_log_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name   = "${local.name_prefix}-vpc-flow-log-policy-${local.suffix}"
  role   = aws_iam_role.vpc_flow_log.id
  policy = data.aws_iam_policy_document.vpc_flow_log_policy.json
}
