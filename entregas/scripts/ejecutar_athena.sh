#!/usr/bin/env bash
# Ejecuta un archivo SQL en el workgroup de Athena, guarda el resultado como CSV
# y registra la ejecucion en evidencias/ejecuciones_athena.csv.
# Uso (desde la raiz del repositorio):
#   bash scripts/ejecutar_athena.sh <etapa> <archivo_sql> <archivo_resultado>
# Ejemplo:
#   bash scripts/ejecutar_athena.sh inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
set -euo pipefail
export AWS_PAGER=""

if [ "$#" -ne 3 ]; then
  echo "Uso: $0 <etapa: inicial|final> <archivo_sql> <archivo_resultado>" >&2
  exit 1
fi
ETAPA=$1; SQL=$2; SALIDA=$3
REGION="us-east-2"
LOG="evidencias/ejecuciones_athena.csv"

BUCKET=$(terraform -chdir=infraestructura output -raw bucket)
DB=$(terraform -chdir=infraestructura output -raw base_de_datos)
WG=$(terraform -chdir=infraestructura output -raw workgroup)

ID=$(aws athena start-query-execution --region "$REGION" --work-group "$WG" \
      --query-execution-context Database="$DB" \
      --query-string "$(cat "$SQL")" \
      --query 'QueryExecutionId' --output text)
echo "Ejecucion iniciada: $ID"

while true; do
  ESTADO=$(aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
            --query 'QueryExecution.Status.State' --output text)
  case "$ESTADO" in
    SUCCEEDED) break ;;
    FAILED|CANCELLED)
      aws athena get-query-execution --region "$REGION" --query-execution-id "$ID" \
        --query 'QueryExecution.Status.StateChangeReason' --output text >&2
      exit 1 ;;
    *) sleep 2 ;;
  esac
done

mkdir -p "$(dirname "$SALIDA")" "$(dirname "$LOG")"
# Athena escribe sus CSV con todos los valores entre comillas; se normalizan (sin comillas innecesarias, finales CRLF como las referencias).
aws s3 cp "s3://$BUCKET/resultados-athena/$ID.csv" - --region "$REGION" \
  | python3 -c 'import csv,sys; csv.writer(sys.stdout, lineterminator="\r\n").writerows(csv.reader(sys.stdin))' \
  > "$SALIDA"

[ -s "$LOG" ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$LOG"
echo "$ETAPA,$SQL,$ID,$SALIDA" >> "$LOG"

echo "Resultado guardado en $SALIDA"
cat "$SALIDA"