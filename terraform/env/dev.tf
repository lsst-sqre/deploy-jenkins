resource "aws_db_instance" "jenkins-demo" {
  skip_final_snapshot     = "true"
  backup_retention_period = 0
}
