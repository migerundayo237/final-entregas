variable "region" {
  description = "Región de AWS donde se despliegan los recursos."
  type        = string
  default     = "us-east-2"
}

variable "nombre_bucket" {
  description = "Nombre del bucket S3. Si es null se usa entregas-examen-<id de cuenta>, que es único por cuenta."
  type        = string
  default     = null
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos en Glue Data Catalog."
  type        = string
  default     = "entregas_db"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa en Glue Data Catalog."
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena."
  type        = string
  default     = "entregas_wg"
}

variable "fecha_inicial" {
  description = "Primera fecha (incluida) de la proyección, formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-01"
}

variable "fecha_final" {
  description = "Última fecha (incluida) de la proyección, formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-03"
}
