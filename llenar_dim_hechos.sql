USE practica3final;

DELIMITER $$

CREATE PROCEDURE llenar_dimensiones_hechos(p_fecha DATE)
BEGIN

  -- 1) Asegurar DIM_fecha para p_fecha
  INSERT IGNORE INTO DIM_fecha (fecha, dia, mes, anio, nombre_dia, nombre_mes, dia_semana)
  VALUES (
    p_fecha,
    DAY(p_fecha),
    MONTH(p_fecha),
    YEAR(p_fecha),
    DAYNAME(p_fecha),
    MONTHNAME(p_fecha),
    DAYOFWEEK(p_fecha)
  );

  -- 2) Asegurar DIM_sucursal (estática)
  INSERT IGNORE INTO DIM_sucursal (id, ciudad, estado, region, pais)
  VALUES
    (1, 'San Cristóbal', 'Táchira', 'Andes', 'Venezuela'),
    (2, 'Valencia', 'Carabobo', 'Centro', 'Venezuela'),
    (3, 'Maracaibo', 'Zulia', 'Occidente', 'Venezuela'),
    (4, 'Caracas', 'Distrito Capital', 'Capital', 'Venezuela'),
    (5, 'Barquisimeto', 'Lara', 'Centro', 'Venezuela');

  -- 3) Upsert DIM_cliente solo para clientes con compras en p_fecha
  INSERT INTO DIM_cliente (id, nombre, sexo, fecha_nacimiento, rango_edad)
  SELECT DISTINCT
    c.id,
    c.nombre,
    c.sexo,
    c.fecha_nacimiento,
    CASE
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 0 AND 5 THEN '0-5'
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 6 AND 12 THEN '6-12'
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 13 AND 17 THEN '13-17'
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 18 AND 24 THEN '18-24'
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 25 AND 34 THEN '25-34'
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 35 AND 44 THEN '35-44'
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 45 AND 54 THEN '45-54'
      WHEN TIMESTAMPDIFF(YEAR, c.fecha_nacimiento, CURDATE()) BETWEEN 55 AND 64 THEN '55-64'
      ELSE '65+'
    END AS rango_edad
  FROM factura f
  JOIN cliente c ON c.id = f.id_cliente
  WHERE f.fecha = p_fecha
  ON DUPLICATE KEY UPDATE
    nombre = VALUES(nombre),
    sexo = VALUES(sexo),
    fecha_nacimiento = VALUES(fecha_nacimiento),
    rango_edad = VALUES(rango_edad);

  -- 4) Upsert DIM_producto solo para productos vendidos en p_fecha
  INSERT INTO DIM_producto (id, nombre)
  SELECT DISTINCT p.id, p.nombre
  FROM factura_producto fp
  JOIN factura f ON f.id = fp.id_factura
  JOIN producto p ON p.id = fp.id_producto
  WHERE f.fecha = p_fecha
  ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

  -- 5) FACT_visita: upsert por cliente-fecha (primeras compras quedan NULL)
  INSERT INTO FACT_visita (id_dim_cliente, id_dim_fecha, dias_desde_ultima_compra)
  SELECT 
    c_ids.id_cliente AS id_dim_cliente,
    df.id             AS id_dim_fecha,
    DATEDIFF(
      p_fecha,
      (
        SELECT MAX(f2.fecha)
        FROM factura f2
        WHERE f2.id_cliente = c_ids.id_cliente AND f2.fecha < p_fecha
      )
    ) AS dias_desde_ultima_compra
  FROM (SELECT DISTINCT id_cliente FROM factura WHERE fecha = p_fecha) c_ids
  JOIN DIM_fecha df ON df.fecha = p_fecha
  ON DUPLICATE KEY UPDATE dias_desde_ultima_compra = VALUES(dias_desde_ultima_compra);

  -- 6) FACT_ventaCombos: recalcular para p_fecha (idempotente por borrar e insertar)
  DELETE FROM FACT_ventaCombos
  WHERE id_DIM_fecha = (SELECT id FROM DIM_fecha WHERE fecha = p_fecha);

  INSERT INTO FACT_ventaCombos (
    id_DIM_fecha,
    id_DIM_producto,
    id_DIM_sucursal,
    cantidad_vendido,
    monto_total_vendido,
    monto_descuento,
    min_promedio_venta_producto
  )
  SELECT 
    df.id AS id_dim_fecha,
    p.id  AS id_dim_producto,
    FLOOR(1 + (RAND() * 5)) AS id_dim_sucursal,
    SUM(fp.cantidad) AS cantidad_vendida,
    SUM((fp.cantidad * fp.precio) - fp.descuento) AS monto_total_vendido,
    ROUND(SUM(fp.descuento), 2) AS monto_descuento,
    ROUND(AVG(fp.precio), 2) AS min_promedio_venta_producto
  FROM factura f
  JOIN factura_producto fp ON f.id = fp.id_factura
  JOIN producto p ON p.id = fp.id_producto
  JOIN DIM_fecha df ON df.fecha = f.fecha
  WHERE f.fecha = p_fecha
  GROUP BY df.id, p.id;

  -- 7) FACT_venta_producto: snapshot total histórico idempotente
  INSERT INTO FACT_venta_producto (id_dim_cliente, id_dim_producto, cantidad_vendida)
  SELECT
    f.id_cliente,
    fp.id_producto,
    SUM(fp.cantidad) AS cantidad_total
  FROM factura_producto fp
  JOIN factura f ON f.id = fp.id_factura
  GROUP BY f.id_cliente, fp.id_producto
  ON DUPLICATE KEY UPDATE cantidad_vendida = VALUES(cantidad_vendida);

END $$

DELIMITER ;



CALL llenar_dimensiones_hechos(CURDATE() - INTERVAL 1 DAY);

SELECT * FROM DIM_producto;
SELECT * FROM DIM_fecha;
SELECT * FROM DIM_sucursal;
SELECT * FROM DIM_cliente;
SELECT * FROM FACT_visita;
SELECT * FROM FACT_venta_producto;
SELECT * FROM FACT_ventaCombos;

-- Limpiar dimensiones y hechos
/*
DROP TABLE DIM_producto;
DROP TABLE DIM_fecha;
DROP TABLE DIM_sucursal;
DROP TABLE DIM_cliente;
DROP TABLE FACT_visita;
DROP TABLE FACT_venta_producto;
DROP TABLE FACT_ventaCombos;
/*