output "db_cluster_endpoint" {
  description = "The connection endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora.endpoint
}

output "db_cluster_port" {
  description = "The port the database is listening on"
  value       = aws_rds_cluster.aurora.port
}

output "db_name" {
  description = "The name of the default database"
  value       = aws_rds_cluster.aurora.database_name
}