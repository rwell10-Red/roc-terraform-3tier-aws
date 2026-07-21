# =============================================================================
# UAT Environment
# =============================================================================

environment = "uat"
project     = "3tier"
owner       = "andre"
region      = "us-east-1"

# Network
vpc_cidr                 = "10.1.0.0/16"
public_subnet_cidr       = "10.1.1.0/24"
public_subnet_cidr_2     = "10.1.4.0/24"
private_app_subnet_cidr  = "10.1.2.0/24"
private_db_subnet_cidr   = "10.1.3.0/24"
private_db_subnet_cidr_2 = "10.1.5.0/24"

# Compute
fe_instance_type    = "t2.micro"
be_instance_type    = "t2.micro"
fe_min_size         = 1
fe_max_size         = 3
fe_desired_capacity = 2
be_min_size         = 1
be_max_size         = 3
be_desired_capacity = 2

# Database
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 50
db_backup_retention_period = 14

# Scaling
scale_out_threshold = 70

# Ports
app_port = 5000
db_port  = 3306
