-- Verificacion del tercer dia (se ejecuta DESPUES de subir fecha=2026-10-03/entregas.csv).
-- Cada sentencia se ejecuta por separado en Athena (una sentencia por ejecucion):
--   1) registros de 2026-10-03          -> resultados/final/verificacion_tercer_dia.csv
--   2) total de registros de la tabla   -> resultados/final/verificacion_total_tabla.csv
--   3) conteo por estado de 2026-10-03  -> resultados/final/verificacion_conteo_estado_tercer_dia.csv

SELECT
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos,
    fecha
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio;

SELECT
    COUNT(*) AS total_registros
FROM entregas_db.entregas;

SELECT
    estado,
    COUNT(*) AS total_intentos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
GROUP BY estado
ORDER BY estado;
