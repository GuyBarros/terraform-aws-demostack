resource "aws_db_subnet_group" "demostack" {
  name       = "${var.namespace}-databases"
  subnet_ids  = aws_subnet.demostack.*.id

}

resource "aws_db_instance" "mysql" {
  identifier           = "${var.namespace}-mysql"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name                 = var.mysql_db_name
  username             = var.mysql_username
  password             = var.mysql_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.demostack.id
  vpc_security_group_ids =[aws_security_group.demostack.id]
  skip_final_snapshot  = true
   timeouts {
    create = "10m"
    delete = "10m"
  }
  publicly_accessible = true
}

# https://github.com/terraform-aws-modules/terraform-aws-rds/tree/master/examples/complete-postgres
resource "aws_db_instance" "postgres" {
identifier           = "${var.namespace}-postgres"
engine               = "postgres"
engine_version         = "17"
instance_class         = "db.t3.micro"

 allocated_storage      = 5
storage_encrypted     = true

db_name     = var.postgres_db_name
username = var.postgres_username
password = var.postgres_password
port     = 5432
db_subnet_group_name = aws_db_subnet_group.demostack.id
vpc_security_group_ids =[aws_security_group.demostack.id]
skip_final_snapshot    = true
 timeouts {
    create = "10m"
    delete = "10m"
  }
  publicly_accessible = true
}


//add mongodb

# resource "aws_docdb_cluster" "docdb" {
#   cluster_identifier      = "${var.namespace}-documentdb"
#   engine                  = "docdb"
#   master_username         =  var.documentdb_master_username
#   master_password         =  var.documentdb_master__password
#   backup_retention_period = 5
#   preferred_backup_window = "07:00-09:00"
#   skip_final_snapshot     = true
#   vpc_security_group_ids =[aws_security_group.demostack.id]
# publicly_accessible = true
# }