# =============================================================================
# Dev Environment
# =============================================================================

environment = "dev"
project     = "3tier"
owner       = "andre"
region      = "us-east-1"

# Network
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidr       = "10.0.1.0/24"
public_subnet_cidr_2     = "10.0.4.0/24"
private_app_subnet_cidr  = "10.0.2.0/24"
private_db_subnet_cidr   = "10.0.3.0/24"
private_db_subnet_cidr_2 = "10.0.5.0/24"

# Compute
fe_instance_type    = "t2.micro"
be_instance_type    = "t2.micro"
fe_min_size         = 1
fe_max_size         = 1
fe_desired_capacity = 1
be_min_size         = 1
be_max_size         = 1
be_desired_capacity = 1

# Database
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_backup_retention_period = 7

# Scaling
scale_out_threshold = 70

# Ports
app_port = 5000
db_port  = 3306
