terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "actual" {}

locals {
  bucket             = coalesce(var.nombre_bucket, "entregas-examen-${data.aws_caller_identity.actual.account_id}")
  prefijo_datos      = "entregas/"
  prefijo_resultados = "resultados-athena/"
}

# ---------------------------------------------------------------------------
# 1. Bucket S3 privado con bloqueo de acceso público
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "datos" {
  bucket        = local.bucket
  force_destroy = true # permite eliminar el bucket aunque contenga datos y resultados
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket = aws_s3_bucket.datos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Los prefijos entregas/ y resultados-athena/ no requieren creación previa:
# forman parte de las claves de los objetos y aparecen al subir archivos.

# ---------------------------------------------------------------------------
# 3. Base de datos de Glue Data Catalog
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "entregas" {
  name        = var.nombre_base_datos
  description = "Base de datos del examen final: intentos de entrega."
}

# ---------------------------------------------------------------------------
# 4. Tabla externa con partition projection
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"               = "TRUE"
    "classification"         = "csv"
    "skip.header.line.count" = "1"

    # Partition projection de fechas: un paso de un día, ambos extremos incluidos
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicial},${var.fecha_final}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"

    # Prefijo de cada partición (termina en /). El $$ evita que Terraform
    # interprete la variable de plantilla de Athena como una interpolación propia.
    "storage.location.template" = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_datos}fecha=$${fecha}/"
  }

  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_datos}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name = "id_envio"
      type = "string"
    }
    columns {
      name = "ciudad"
      type = "string"
    }
    columns {
      name = "transportadora"
      type = "string"
    }
    columns {
      name = "estado"
      type = "string"
    }
    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# ---------------------------------------------------------------------------
# 5. Workgroup de Athena con resultados en resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_athena_workgroup" "entregas" {
  name          = var.nombre_workgroup
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_resultados}"
    }
  }
}
