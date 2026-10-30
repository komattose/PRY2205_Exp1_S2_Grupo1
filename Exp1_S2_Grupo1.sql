/* ============================================================
   PRY2205 - Consulta de Bases de Datos
   Actividad Formativa 2: Creando consultas utilizando funciones SQL
   Grupo 1: Martin Belaunde - Luciano Maldonado
   Usuario: PRY2205_S2 (conexión PRY2205_ACTIVIDAD_S2)
   ============================================================ */


/* ------------------------------------------------------------
   CASO 1: Análisis de Facturas
   Facturas emitidas el año anterior al año de ejecución.
   ------------------------------------------------------------ */
SELECT
    f.numfactura                                                   AS "N° Factura",
    TO_CHAR(f.fecha, 'DD "de" Month YYYY', 'NLS_DATE_LANGUAGE=SPANISH')
                                                                   AS "Fecha Emisión",
    LPAD(f.rutcliente, 10, '0')                                    AS "RUT Cliente",
    TO_CHAR(ROUND(f.neto), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
                                                                   AS "Monto Neto",
    TO_CHAR(ROUND(f.iva), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
                                                                   AS "Monto Iva",
    TO_CHAR(ROUND(f.total), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
                                                                   AS "Total Factura",
    CASE
        WHEN f.total BETWEEN 0 AND 50000      THEN 'Bajo'
        WHEN f.total BETWEEN 50001 AND 100000 THEN 'Medio'
        ELSE 'Alto'
    END                                                            AS "Categoría Monto",
    DECODE(f.codpago,
           1, 'EFECTIVO',
           2, 'TARJETA DEBITO',
           3, 'TARJETA CREDITO',
              'CHEQUE')                                            AS "Forma de pago"
FROM factura f
WHERE EXTRACT(YEAR FROM f.fecha) = EXTRACT(YEAR FROM SYSDATE) - 1
ORDER BY f.fecha DESC, f.neto DESC;


/* ------------------------------------------------------------
   CASO 2: Clasificación de Clientes
   Clientes con estado 'A' y crédito mayor a 0.
   ------------------------------------------------------------ */
SELECT
    LPAD(c.rutcliente, 12, '*')                                    AS "RUT",
    INITCAP(c.nombre)                                              AS "Cliente",
    NVL(TO_CHAR(c.telefono), 'Sin teléfono')                       AS "TELÉFONO",
    NVL(TO_CHAR(c.codcomuna), 'Sin comuna')                        AS "COMUNA",
    c.estado                                                       AS "ESTADO",
    CASE
        WHEN NVL(c.saldo, 0) / c.credito < 0.5 THEN
            'Bueno (' || TO_CHAR(ROUND(c.credito - NVL(c.saldo, 0)), '$9G999G999',
                                 'NLS_NUMERIC_CHARACTERS='',.''') || ')'
        WHEN NVL(c.saldo, 0) / c.credito <= 0.8 THEN
            'Regular (' || TO_CHAR(ROUND(NVL(c.saldo, 0)), '$9G999G999',
                                   'NLS_NUMERIC_CHARACTERS='',.''') || ')'
        ELSE 'Crítico'
    END                                                            AS "Estado Crédito",
    NVL(UPPER(SUBSTR(c.mail, INSTR(c.mail, '@') + 1)), 'Correo no registrado')
                                                                   AS "Dominio Correo"
FROM cliente c
WHERE c.estado = 'A'
  AND c.credito > 0
ORDER BY c.nombre ASC;


/* ------------------------------------------------------------
   CASO 3: Stock de productos
   Productos con "zapato" en la descripción y procedencia 'I'.
   Variables de sustitución: TIPOCAMBIO_DOLAR, UMBRAL_BAJO, UMBRAL_ALTO
   ------------------------------------------------------------ */
SELECT
    p.codproducto                                                  AS "ID",
    INITCAP(p.descripcion)                                         AS "Descripción de Producto",
    LPAD(NVL2(p.valorcompradolar,
              TO_CHAR(p.valorcompradolar, 'TM9', 'NLS_NUMERIC_CHARACTERS='',.''') || ' USD',
              'Sin registro'), 14)                                 AS "Compra en USD",
    LPAD(NVL2(p.valorcompradolar,
              TO_CHAR(ROUND(p.valorcompradolar * &&TIPOCAMBIO_DOLAR), 'FM$999G999G999',
                      'NLS_NUMERIC_CHARACTERS='',.''') || ' PESOS',
              'Sin registro'), 18)                                 AS "USD convertido",
    p.totalstock                                                   AS "Stock",
    CASE
        WHEN p.totalstock IS NULL            THEN 'Sin datos'
        WHEN p.totalstock < &&UMBRAL_BAJO    THEN '¡ALERTA stock muy bajo!'
        WHEN p.totalstock <= &&UMBRAL_ALTO   THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END                                                            AS "Alerta Stock",
    LPAD(CASE
             WHEN p.totalstock > 80 THEN
                 TO_CHAR(ROUND(p.vunitario * 0.9), 'FM$999G999G999',
                         'NLS_NUMERIC_CHARACTERS='',.''')
             ELSE 'N/A'
         END, 12)                                                  AS "Precio Oferta"
FROM producto p
WHERE UPPER(p.descripcion) LIKE '%ZAPATO%'
  AND UPPER(p.procedencia) = 'I'
ORDER BY p.codproducto DESC;

UNDEFINE TIPOCAMBIO_DOLAR
UNDEFINE UMBRAL_BAJO
UNDEFINE UMBRAL_ALTO
