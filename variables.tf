# Retrieves the identity (subscriber id) of you AWS account
data "aws_caller_identity" "current" {}
# Retrieves the regions you are targeting
data "aws_region" "current"         { current = true }

variable "environment"              { default = "rds" }

# The id of the VPC
variable "vpc_id"                   {}
# The name of the database
variable "rds_dbname"               { default = "databasename" }
# The instance class of the RDS database
variable "rds_instance_class"       { default = "db.t2.medium" }
# The user name of the master user
variable "rds_user"                 { default = "username" }
# The password of the master user
variable "rds_password"             {}
# Retention of the RDS cluster
variable "rds_retention_in_days"    { default = 7 }
# The window in which the backup will start
variable "rds_backup_window"        { default = "00:00-01:00" }
# The preferred maintenance window
variable "rds_maintenance_window"   { default = "mon:01:30-mon:02:30" }
# The RDS type
variable "rds_parameter_group_name" { default = "default.aurora5.6" }
# The retention used by the backup script (days)
variable "retention_count_daily"    { default = 6 }
# The retention used by the backup script (weeks)
variable "retention_count_weekly"   { default = 4 }
# The retention used by the backup script (months)
variable "retention_count_monthly"  { default = 12 }
# Prefix used by KMS key alias
variable "kms_purpose"              { default = "rds" }
# Description for the KMS key
variable "kms_description"          { default = "kms key for rds encryption" }

# The security groups that are allows to connect to the RDS cluster
variable "security_group_list" {
  type    = "list"
  default = []
}

# The subnets in which your RDS needs to be available (at least two)
variable "subnet_list" {
  type    = "list"
  default = []
}

# The availability zones in which your RDS needs to be available (at least two), these must match the AV zones in the
# subnet list
variable "av_zone_list" {
  type    = "list"
  default = []
}

# Resource that is used to retrieve the VPC - do not alter
data "aws_vpc" "default_vpc"        { id = "${var.vpc_id}" }
