# The security group for the RDS instances
resource "aws_security_group" "rds" {
  name                = "${var.environment}-${var.rds_dbname}-rds"
  description         = "${var.environment}-${var.rds_dbname}-rds"
  vpc_id              = "${data.aws_vpc.default_vpc.id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${concat(list(aws_security_group.rds_instance_access.id), var.security_group_list)}"]
    self            = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name            = "${var.rds_dbname}-rds-sg"
    Environment     = "${var.environment}"
    Terraform       = "True"
  }
}

# The security group for instances that are allowed to access the RDS cluster
resource "aws_security_group" "rds_instance_access" {
  name        = "${var.environment}-rds-access"
  description = "security group for accessing rds"
  vpc_id      = "${data.aws_vpc.default_vpc.id}"

  tags {
    Name            = "${var.environment}-rds-access"
    Environment     = "${var.environment}"
    Terraform       = "True"
  }
}

# The security group role that allows EC2 instances in rds_instance_access group to access the RDS instances
resource "aws_security_group_rule" "instance_to_rds" {
  type            = "egress"
  from_port       = 1024
  to_port         = 65535
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.rds.id}"

  security_group_id = "${aws_security_group.rds_instance_access.id}"
}

output "sg_rds_access" { value = "${aws_security_group.rds_instance_access.id}" }