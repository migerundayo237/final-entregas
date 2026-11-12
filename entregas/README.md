# Examen final: Entregas con Athena, Glue y partition projection

Ingeniería de Datos - Universidad EIA - 2026-2

Una empresa de mensajería consulta resultados de intentos de entrega desde Athena. Los CSV viven en S3,
Glue Data Catalog guarda el esquema y las reglas de partition projection, y Athena consulta sin crawlers
ni registro manual de particiones.

## 1. Prerrequisitos

| Herramienta | Versión recomendada | Verificación |
| --- | --- | --- |
| Git | cualquiera reciente | `git --version` |
| AWS CLI | v2 | `aws --version` |
| Terraform | >= 1.5 | `terraform version` |
| Cuenta AWS con permisos sobre S3, Glue y Athena | - | `aws sts get-caller-identity` |

- **Región usada:** `us-east-2` (se configura en `infraestructura/variables.tf`).
- **Credenciales:** se configuran localmente con `aws configure` o variables de entorno
  (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` si aplica).
  **Nunca** se suben al repositorio (ver `.gitignore`).

## 2. Estructura del repositorio

```
.
├── README.md
├── .gitignore
├── data/entregas/fecha=2026-10-0{1,2,3}/entregas.csv   (suministrado, sin modificar)
├── resultados_esperados/                                (suministrado, sin modificar)
├── infraestructura/    principal.tf, variables.tf, salidas.tf
├── consultas/          SQL de la demostración
├── resultados/         inicial/ y final/ (CSV obtenidos en Athena)
├── evidencias/         aplicacion_terraform.txt, outputs.json, ejecuciones_athena.csv, eliminacion_terraform.txt
├── respuestas.md
└── chats/              conversaciones con herramientas de IA usadas en el examen
```

## 3. Configuración y despliegue
_Pendiente de documentar._

## 4. Carga de archivos - etapa inicial (días 1 y 2)
_Pendiente de documentar._

## 5. Consultas y resultados iniciales
_Pendiente de documentar._

## 6. Incorporación de una nueva fecha (día 3)
_Pendiente de documentar._

## 7. Limpieza
_Pendiente de documentar._
