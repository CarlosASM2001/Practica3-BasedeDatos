USE practica3final;

DELIMITER $$

CREATE PROCEDURE llenar_dimensiones_hechos()
BEGIN

  -- Limpieza de hechos para evitar duplicados en recargas
  TRUNCATE TABLE FACT_venta_producto;
  TRUNCATE TABLE FACT_visita;
  TRUNCATE TABLE FACT_ventaCombos;

  -- Reset DIM_fecha para que sus IDs sigan el orden cronológico de la fecha
  DELETE FROM DIM_fecha;
  ALTER TABLE DIM_fecha AUTO_INCREMENT = 1;

  -- 1. Llenar DIM_producto
  INSERT INTO DIM_producto (id, nombre)
  SELECT p.id, p.nombre
  FROM producto p
  ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

  -- 2. Llenar DIM_cliente
  INSERT INTO DIM_cliente (id, nombre, sexo, fecha_nacimiento, cliente_tipo)
  SELECT
    id,
    nombre,
    sexo,
    fecha_nacimiento,
    CASE
      WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE()) < 18 THEN 'nino'
      ELSE 'adulto'
    END
  FROM cliente
  ON DUPLICATE KEY UPDATE
    nombre = VALUES(nombre),
    sexo = VALUES(sexo),
    fecha_nacimiento = VALUES(fecha_nacimiento),
    cliente_tipo = VALUES(cliente_tipo);

  -- 3. Llenar DIM_fecha (únicas desde factura)
  INSERT IGNORE INTO DIM_fecha (fecha, dia, mes, anio, nombre_dia, nombre_mes, dia_semana)
  SELECT DISTINCT
    fecha,
    DAY(fecha),
    MONTH(fecha),
    YEAR(fecha),
    DAYNAME(fecha),
    MONTHNAME(fecha),
    DAYOFWEEK(fecha)
  FROM factura
  ORDER BY fecha;

  -- 4. Llenar DIM_sucursal (ficticia)
  INSERT IGNORE INTO DIM_sucursal (id, ciudad, estado, region, pais)
  VALUES
    (1, 'San Cristóbal', 'Táchira', 'Andes', 'Venezuela'),
    (2, 'Valencia', 'Carabobo', 'Centro', 'Venezuela'),
    (3, 'Maracaibo', 'Zulia', 'Occidente', 'Venezuela'),
    (4, 'Caracas', 'Distrito Capital', 'Capital', 'Venezuela'),
    (5, 'Barquisimeto', 'Lara', 'Centro', 'Venezuela');

  -- 5. Llenar FACT_venta_producto
  INSERT INTO FACT_venta_producto (id_dim_cliente, id_dim_producto, cantidad_vendida)
  SELECT
    f.id_cliente,
    fp.id_producto,
    SUM(fp.cantidad)
  FROM factura_producto fp
  JOIN factura f ON f.id = fp.id_factura
  GROUP BY f.id_cliente, fp.id_producto;

  -- 6. Llenar FACT_visita (primeras compras quedan NULL; una fila por cliente y fecha)
  INSERT INTO FACT_visita (id_dim_cliente, id_dim_fecha, dias_desde_ultima_compra)
  SELECT
    t.id_cliente,
    df.id,
    TIMESTAMPDIFF(DAY, t.prev_fecha, t.fecha) AS dias_desde_ultima_compra
  FROM (
    SELECT
      f.id_cliente,
      f.fecha,
      LAG(f.fecha) OVER (PARTITION BY f.id_cliente ORDER BY f.fecha) AS prev_fecha
    FROM (
      SELECT DISTINCT id_cliente, fecha FROM factura
    ) f
  ) t
  JOIN DIM_fecha df ON df.fecha = t.fecha;

  -- 7. Llenar FACT_ventaCombos
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
    p.id AS id_dim_producto,
    FLOOR(1 + (RAND() * 5)) AS id_dim_sucursal, -- sucursal aleatoria
    SUM(fp.cantidad) AS cantidad_vendida,
    SUM((fp.cantidad * fp.precio) - fp.descuento) AS monto_total_vendido,
    ROUND(SUM(fp.descuento), 2) AS monto_descuento,
    ROUND(AVG(fp.precio), 2) AS min_promedio_venta_producto
  FROM factura f
  JOIN factura_producto fp ON f.id = fp.id_factura
  JOIN producto p ON p.id = fp.id_producto
  JOIN DIM_fecha df ON df.fecha = f.fecha
  GROUP BY df.id, p.id;

END $$

DELIMITER ;



CALL llenar_dimensiones_hechos();

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