# =============================================================================
# Region
# =============================================================================

variable "region" {
  type        = string
  description = "AWS region for all resources"
  default     = "us-east-1"
}

# =============================================================================
# Network Variables
# =============================================================================

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block (RFC 1918, /16 to /24)"

  validation {
    condition = can(cidrhost(var.vpc_cidr, 0)) && (
      (parseint(split(".", cidrhost(var.vpc_cidr, 0))[0], 10) == 10) ||
      (parseint(split(".", cidrhost(var.vpc_cidr, 0))[0], 10) == 172 &&
        parseint(split(".", cidrhost(var.vpc_cidr, 0))[1], 10) >= 16 &&
      parseint(split(".", cidrhost(var.vpc_cidr, 0))[1], 10) <= 31) ||
      (parseint(split(".", cidrhost(var.vpc_cidr, 0))[0], 10) == 192 &&
      parseint(split(".", cidrhost(var.vpc_cidr, 0))[1], 10) == 168)
    )
    error_message = "VPC CIDR must be a valid RFC 1918 private address range (10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16)."
  }

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "VPC CIDR prefix length must be between /16 and /24."
  }
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr_2" {
  type        = string
  description = "CIDR block for the second public subnet (required by ALB)"
  default     = "10.0.4.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr_2, 0))
    error_message = "Public subnet 2 CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_app_subnet_cidr" {
  type        = string
  description = "CIDR block for the private application subnet"
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_app_subnet_cidr, 0))
    error_message = "Private app subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_db_subnet_cidr" {
  type        = string
  description = "CIDR block for the private database subnet"
  default     = "10.0.3.0/24"

  validation {
    condition     = can(cidrhost(var.private_db_subnet_cidr, 0))
    error_message = "Private DB subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_db_subnet_cidr_2" {
  type        = string
  description = "CIDR block for the second private database subnet (required by RDS)"
  default     = "10.0.5.0/24"

  validation {
    condition     = can(cidrhost(var.private_db_subnet_cidr_2, 0))
    error_message = "Private DB subnet 2 CIDR must be a valid IPv4 CIDR block."
  }
}

# =============================================================================
# Front-End Variables
# =============================================================================

variable "fe_instance_type" {
  type        = string
  description = "Instance type for front-end instances"
  default     = "t2.micro"
}

variable "fe_min_size" {
  type        = number
  description = "Minimum number of front-end instances in the ASG"
  default     = 1

  validation {
    condition     = var.fe_min_size >= 1
    error_message = "Front-end minimum capacity must be at least 1."
  }
}

variable "fe_max_size" {
  type        = number
  description = "Maximum number of front-end instances in the ASG"
  default     = 3

  validation {
    condition     = var.fe_max_size >= var.fe_min_size
    error_message = "Front-end maximum capacity must be greater than or equal to minimum capacity."
  }
}

variable "fe_desired_capacity" {
  type        = number
  description = "Desired number of front-end instances in the ASG"
  default     = 1

  validation {
    condition     = var.fe_desired_capacity >= var.fe_min_size && var.fe_desired_capacity <= var.fe_max_size
    error_message = "Front-end desired capacity must be between minimum and maximum capacity."
  }
}

variable "fe_user_data" {
  type        = string
  description = "User data script for front-end instances"
  default     = ""
}

# =============================================================================
# Back-End Variables
# =============================================================================

variable "be_instance_type" {
  type        = string
  description = "Instance type for back-end instances"
  default     = "t2.micro"
}

variable "be_min_size" {
  type        = number
  description = "Minimum number of back-end instances in the ASG"
  default     = 1

  validation {
    condition     = var.be_min_size >= 1
    error_message = "Back-end minimum capacity must be at least 1."
  }
}

variable "be_max_size" {
  type        = number
  description = "Maximum number of back-end instances in the ASG"
  default     = 3

  validation {
    condition     = var.be_max_size >= var.be_min_size
    error_message = "Back-end maximum capacity must be greater than or equal to minimum capacity."
  }
}

variable "be_desired_capacity" {
  type        = number
  description = "Desired number of back-end instances in the ASG"
  default     = 1

  validation {
    condition     = var.be_desired_capacity >= var.be_min_size && var.be_desired_capacity <= var.be_max_size
    error_message = "Back-end desired capacity must be between minimum and maximum capacity."
  }
}

variable "be_user_data" {
  type        = string
  description = "User data script for back-end instances"
  default     = ""
}

variable "app_port" {
  type        = number
  description = "Back-end application port"
  default     = 8000

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "be_additional_policy_arns" {
  type        = list(string)
  description = "Additional IAM policy ARNs to attach to the back-end role"
  default     = []
}

# =============================================================================
# Database Variables
# =============================================================================

variable "db_engine_version" {
  type        = string
  description = "MySQL engine version for RDS"
  default     = "8.0"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage for the RDS instance in GB"
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "RDS allocated storage must be between 20 and 65536 GB."
  }
}

variable "db_port" {
  type        = number
  description = "Database port for RDS"
  default     = 3306

  validation {
    condition     = var.db_port >= 1 && var.db_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS instance"
  default     = "admin"
}

variable "db_backup_retention_period" {
  type        = number
  description = "Number of days to retain automated RDS backups"
  default     = 7

  validation {
    condition     = var.db_backup_retention_period >= 7 && var.db_backup_retention_period <= 35
    error_message = "RDS backup retention period must be between 7 and 35 days."
  }
}

variable "db_kms_key_id" {
  type        = string
  description = "Custom KMS key ARN for RDS encryption. Empty string uses the AWS-managed default key."
  default     = ""
}

# =============================================================================
# Scaling Variables
# =============================================================================

variable "scale_out_threshold" {
  type        = number
  description = "CPU utilization percentage to trigger scale-out"
  default     = 70
}

variable "scale_in_threshold" {
  type        = number
  description = "CPU utilization percentage to trigger scale-in"
  default     = 30
}

variable "scaling_cooldown" {
  type        = number
  description = "Cooldown period in seconds between scaling actions"
  default     = 300
}

# =============================================================================
# Tag Variables
# =============================================================================

variable "environment" {
  type        = string
  description = "Deployment environment (dev, uat, prod)"

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "project" {
  type        = string
  description = "Project name for resource tagging"
}

variable "owner" {
  type        = string
  description = "Owner of the resources for tagging"
}
