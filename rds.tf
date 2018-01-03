# RDS Cluster instance
resource "aws_rds_cluster_instance" "instance" {
  identifier              = "${var.rds_dbname}"
  cluster_identifier      = "${aws_rds_cluster.cluster.id}"
  publicly_accessible     = false
  db_subnet_group_name    = "${aws_db_subnet_group.sng.name}"
  db_parameter_group_name = "${var.rds_parameter_group_name}"

  instance_class          = "${var.rds_instance_class}"

  tags {
    Environment         = "${var.environment}"
    Type                = "${var.environment}-${var.rds_dbname}-rds"
    Terraform           = "true"
  }
}

# RDS Cluster
resource "aws_rds_cluster" "cluster" {
  cluster_identifier      = "${var.rds_dbname}"
  availability_zones      = ["${var.av_zone_list}"]
  database_name           = "${var.rds_dbname}"
  master_username         = "${var.rds_user}"
  master_password         = "${var.rds_password}"
  backup_retention_period = "${var.rds_retention_in_days}"
  preferred_backup_window = "${var.rds_backup_window}"
  vpc_security_group_ids  = ["${aws_security_group.rds.id}"]
  port                    = 3306
  db_subnet_group_name    = "${aws_db_subnet_group.sng.name}"
  storage_encrypted       = true
  kms_key_id              = "${aws_kms_key.kms_key.arn}"
}

# The subnet group where the RDS cluster resides in
resource "aws_db_subnet_group" "sng" {
  name                    = "${var.environment}-subnet-group"
  subnet_ids              = ["${var.subnet_list}"]

  tags {
    Name = "${var.environment}-subnet-group"
    Terraform           = "true"
  }
}

output "rds_cluster_endpoint" { value = "${aws_rds_cluster.cluster.endpoint}"}
output "rds_cluster_database_name" { value = "${aws_rds_cluster.cluster.database_name}"}