# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla usa partition projection y no particiones registradas una por una. En Glue no existe ninguna
partición guardada: lo que existe son propiedades de la tabla (`projection.fecha.type=date`,
`format=yyyy-MM-dd`, `range=2026-10-01,2026-10-03`, `interval=1`, `interval.unit=DAYS` y
`storage.location.template=s3://<bucket>/entregas/fecha=${fecha}/`). Cuando Athena recibe una consulta,
calcula con esas reglas la lista de fechas posibles y la ruta de cada una, y lee lo que encuentre en esos prefijos.

El 2026-10-03 ya estaba dentro del rango desde el despliegue inicial, así que esa partición existía "virtualmente"
aunque no hubiera ningún objeto en S3. En la etapa inicial no devolvía filas porque el prefijo estaba vacío
(la tabla tenía 12 registros). Al subir `entregas/fecha=2026-10-03/entregas.csv`, que respeta la estructura de
carpetas y el esquema configurados, el mismo cálculo encontró el archivo y la tabla pasó a 18 registros
(`resultados/final/verificacion_total_tabla.csv`), con los seis registros del día en
`resultados/final/verificacion_tercer_dia.csv`.

La evidencia de que no se tocó nada más: `evidencias/aplicacion_terraform.txt` contiene una sola aplicación
(5 recursos creados, antes de subir ningún archivo), y entre la etapa inicial y la final no se ejecutó crawler,
`MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`. Solo se subió el archivo y se volvió a consultar; las consultas
agregadas no tenían filtro de fechas, por eso el mismo SQL devolvió 9 filas de intentos y 6 de porcentajes
(`resultados/final/`), idénticas a las referencias finales.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

Se esperaría que el archivo quedara guardado en S3 pero que Athena no lo viera. El 2026-10-04 está fuera del rango
`2026-10-01,2026-10-03`, así que Athena no genera esa partición al proyectar. Las consultas sin filtro seguirían
devolviendo los mismos 18 registros, y una consulta con `WHERE fecha = '2026-10-04'` devolvería cero filas, sin
mostrar error. La proyección no crea datos ni amplía sola el rango: solo calcula lo que las propiedades permiten.

Para incluirlo habría que ampliar el rango de la proyección en Terraform, cambiando `fecha_final` (variable en
`infraestructura/variables.tf`, que alimenta `projection.fecha.range`) a `2026-10-04` y ejecutando `terraform apply`.
Es un cambio en una propiedad de la tabla, no en las particiones. Otra opción es usar `NOW` como límite superior
del rango (`2026-10-01,NOW`), para que las fechas nuevas se incluyan sin volver a editar la tabla, siempre que el
archivo respete la ruta `entregas/fecha=yyyy-MM-dd/entregas.csv`. Aun así, ese cambio también se haría en Terraform
y no en la consola.