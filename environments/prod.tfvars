# =============================================================================
# Prod Environment
# =============================================================================

environment = "prod"
project     = "3tier"
owner       = "andre"
region      = "us-east-1"

# Network
vpc_cidr                 = "10.2.0.0/16"
public_subnet_cidr       = "10.2.1.0/24"
public_subnet_cidr_2     = "10.2.4.0/24"
private_app_subnet_cidr  = "10.2.2.0/24"
private_db_subnet_cidr   = "10.2.3.0/24"
private_db_subnet_cidr_2 = "10.2.5.0/24"

# Compute
fe_instance_type    = "t2.micro"
be_instance_type    = "t2.micro"
fe_min_size         = 2
fe_max_size         = 5
fe_desired_capacity = 2
be_min_size         = 2
be_max_size         = 5
be_desired_capacity = 2

# Database
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 100
db_backup_retention_period = 35

# Scaling
scale_out_threshold = 60

# Ports
app_port = 5000
db_port  = 3306
