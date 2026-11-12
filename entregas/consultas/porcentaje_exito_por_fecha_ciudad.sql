-- 100 * entregas exitosas / total de intentos (todos los estados) por fecha y ciudad.
-- Se usa DOUBLE para evitar la division entera y CAST a DECIMAL(5,2) para conservar dos decimales.
SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(100.0 * CAST(COUNT_IF(estado = 'entregado') AS DOUBLE) / COUNT(*), 2)
        AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM entregas_db.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
