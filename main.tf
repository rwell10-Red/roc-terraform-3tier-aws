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

  backend "s3" {
    bucket       = "roc-terraform-3tier-state-x1go"
    key          = "terraform-3tier-aws/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
    }
  }
}

# =============================================================================
# Data Sources
# =============================================================================

# Auto-select first available AZ in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Auto-lookup latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# Auto-generated DB Password
# =============================================================================

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}|:,.<>?"
}

# =============================================================================
# Random Suffix for Unique Naming
# =============================================================================

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# =============================================================================
# Locals
# =============================================================================

locals {
  availability_zone   = data.aws_availability_zones.available.names[0]
  availability_zone_2 = data.aws_availability_zones.available.names[1]
  ami_id              = data.aws_ami.amazon_linux.id

  # Naming convention: {env}-{project}-{resource}-{suffix}
  name_prefix  = "${var.environment}-${var.project}"
  short_prefix = "${var.environment}-${substr(var.project, 0, 4)}"
  suffix       = random_string.suffix.result
}
