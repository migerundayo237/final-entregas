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

Todos los comandos se ejecutan desde la raíz del repositorio salvo que se indique otra cosa.

1. Verificar las credenciales y la cuenta:
   ```bash
   aws sts get-caller-identity
   ```
2. Desplegar la infraestructura (región `us-east-2`, definida en `infraestructura/variables.tf`):
   ```bash
   cd infraestructura
   terraform init
   terraform fmt
   terraform validate
   terraform apply -no-color -auto-approve 2>&1 | tee ../evidencias/aplicacion_terraform.txt
   terraform output -json > ../evidencias/outputs.json
   cd ..
   ```
3. Recursos creados (5): bucket S3 privado `entregas-examen-<id de cuenta>` con bloqueo de acceso público,
   base de datos Glue `entregas_db`, tabla externa `entregas` con partition projection, y workgroup de Athena
   `entregas_wg` con resultados en `s3://<bucket>/resultados-athena/`.
4. Propiedades de proyección de la tabla (todas definidas en Terraform, sin particiones individuales):
   `projection.fecha.type=date`, `format=yyyy-MM-dd`, `range=2026-10-01,2026-10-03`, `interval=1`,
   `interval.unit=DAYS` y `storage.location.template=s3://<bucket>/entregas/fecha=${fecha}/`.
5. Verificación de la plantilla de ubicación registrada en Glue:
   ```bash
   aws glue get-table --database-name entregas_db --name entregas --region us-east-2 \
     --no-cli-pager --query 'Table.Parameters."storage.location.template"' --output text
   ```

## 4. Carga de archivos - etapa inicial (días 1 y 2)

Solo se cargan los archivos de los días 1 y 2, uno por uno (sin `--recursive` ni `sync`). El archivo del día 3
permanece únicamente en local hasta la sección 6.

```bash
BUCKET=$(terraform -chdir=infraestructura output -raw bucket)

aws s3 cp data/entregas/fecha=2026-10-01/entregas.csv \
  s3://$BUCKET/entregas/fecha=2026-10-01/entregas.csv --region us-east-2

aws s3 cp data/entregas/fecha=2026-10-02/entregas.csv \
  s3://$BUCKET/entregas/fecha=2026-10-02/entregas.csv --region us-east-2
```

Verificación de que solo existen los dos objetos esperados:

```bash
aws s3 ls s3://$BUCKET/entregas/ --recursive --region us-east-2
```

Resultado esperado: dos objetos (`fecha=2026-10-01/entregas.csv` y `fecha=2026-10-02/entregas.csv`),
12 registros de datos en total. No existe ningún objeto para `fecha=2026-10-03`.

## 5. Consultas y resultados iniciales

Las consultas están en `consultas/` y se ejecutan en el workgroup `entregas_wg` con el script
`scripts/ejecutar_athena.sh`, que lanza la consulta, espera su finalización, guarda el resultado en CSV
(sin comillas, finales de línea CRLF, igual que las referencias suministradas) y registra la ejecución en `evidencias/ejecuciones_athena.csv`
(`etapa`, `archivo_sql`, `id_ejecucion`, `archivo_resultado`). Se ejecuta desde la raíz del repositorio:

```bash
bash scripts/ejecutar_athena.sh inicial consultas/intentos_por_fecha_estado.sql \
  resultados/inicial/intentos_por_fecha_estado.csv

bash scripts/ejecutar_athena.sh inicial consultas/porcentaje_exito_por_fecha_ciudad.sql \
  resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv

bash scripts/ejecutar_athena.sh inicial consultas/duracion_promedio_2026-10-02.sql \
  resultados/inicial/duracion_promedio_2026-10-02.csv
```

Comparación con las referencias suministradas (sin salida = idénticos):

```bash
diff resultados/inicial/intentos_por_fecha_estado.csv resultados_esperados/intentos_por_fecha_estado_inicial.csv
diff resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv resultados_esperados/porcentaje_exito_por_fecha_ciudad_inicial.csv
diff resultados/inicial/duracion_promedio_2026-10-02.csv resultados_esperados/duracion_promedio_2026-10-02.csv
```

Notas de diseño de las consultas:
- Ninguna consulta filtra por rango de fechas (salvo el promedio, que pide solo el 2026-10-02), por lo que el mismo SQL sirve para ambas etapas.
- El porcentaje usa `DOUBLE` para evitar división entera y `CAST ... AS DECIMAL(5,2)` para conservar dos decimales; el denominador cuenta todos los estados.
- El promedio filtra `estado = 'entregado'` para no incluir los ceros de los intentos fallidos.

## 6. Incorporación de una nueva fecha (día 3)
_Pendiente de documentar._

## 7. Limpieza
_Pendiente de documentar._
