terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# Random suffix for globally unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  bucket_name = "roc-terraform-3tier-state-${random_string.bucket_suffix.result}"
}

# =============================================================================
# S3 State Bucket
# =============================================================================

resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Purpose     = "Terraform remote state"
    Project     = "3tier"
    Owner       = "andre"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# Outputs
# =============================================================================

output "bucket_name" {
  value       = aws_s3_bucket.state.bucket
  description = "S3 bucket name — use this in your main project's backend config"
}

output "bucket_arn" {
  value = aws_s3_bucket.state.arn
}
