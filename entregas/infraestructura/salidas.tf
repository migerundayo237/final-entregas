output "bucket" {
  description = "Nombre del bucket S3."
  value       = aws_s3_bucket.datos.bucket
}

output "base_de_datos" {
  description = "Nombre de la base de datos en Glue Data Catalog."
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla" {
  description = "Nombre de la tabla externa en Glue Data Catalog."
  value       = aws_glue_catalog_table.entregas.name
}

output "workgroup" {
  description = "Nombre del workgroup de Athena."
  value       = aws_athena_workgroup.entregas.name
}

output "region" {
  description = "Región de despliegue."
  value       = var.region
}
