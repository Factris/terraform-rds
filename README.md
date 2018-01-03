# terraform-rds

This a terraform module to set up a RDS cluster (Aurora) on Amazon Web Services (AWS). Terraform is a powerful tool which allows you to 
maintain your infrastructure in code completely. You can set up your RDS cluster in minutes. 
No need to click around in the console. To learn more about Terraform click [here](https://www.terraform.io/intro/index.html).
 
## Features
- A RDS cluster with encrypted storage (by using KMS)
- Daily backups with daily, weekly, and monthly retention
- Creates a security group (rds_instance_access)from which you can access your RDS cluster

## Requirements
- Terraform CLI (v0.9.11)
- AWS account
- An AWS VPC in which you can setup your database

## Usage
Create a terraform [configuration](https://www.terraform.io/intro/getting-started/build.html#configuration) and include 
the following:

    module "rds" {
      source              = "githuburl"
      environment         = "${var.environment}"
      vpc_id              = "${var.vpc_id}"
      rds_user            = "${var.rds_user}"
      rds_dbname          = "${var.rds_dbname}"
      rds_password        = "${var.rds_password}"
      subnet_list         = "${var.private_subnet_list}"
      av_zone_list        = "${var.av_zone_list_rds}"
      security_group_list = "${var.sg_list}"
      rds_backup_script   = "${var.rds_backup_script}"
    }

Apply your Terraform configuration. 

## Notes

When you delete a RDS Cluster on AWS all associated snapshots become useless. Also, RDS supports retention of 30 days. 
Because of this another backup policy is used in this setup. It copies the latest RDS snapshot and keeps daily, weekly 
and monthly backups.
If you delete your KMS key you lose access to your database and snapshots. Use ` prevent_destroy  = "true"` on your RDS 
cluster/instances and KMS keys.

