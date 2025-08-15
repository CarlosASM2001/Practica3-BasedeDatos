DELIMITER $$

CREATE PROCEDURE llenar_dimensiones_hechos()
BEGIN

  -- 1. Llenar dim_producto
  INSERT INTO dim_producto (id, nombre, precio)
  SELECT id, nombre, precio FROM producto;

  -- 2. Llenar dim_cliente
  INSERT INTO dim_cliente (id, nombre, sexo, fecha_nacimiento, cliente_tipo)
  SELECT
    id,
    nombre,
    sexo,
    fecha_nacimiento,
    CASE
      WHEN TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE()) < 18 THEN 'nino'
      ELSE 'adulto'
    END
  FROM cliente;

  -- 3. Llenar dim_fecha (únicas desde factura)
  INSERT INTO dim_fecha (fecha, dia, mes, anio, nombre_dia, nombre_mes, dia_semana)
  SELECT DISTINCT
    fecha,
    DAY(fecha),
    MONTH(fecha),
    YEAR(fecha),
    DAYNAME(fecha),
    MONTHNAME(fecha),
    DAYOFWEEK(fecha)
  FROM factura;

  -- 4. Llenar dim_sucursal (ficticia)
  INSERT INTO dim_sucursal (id, ciudad, estado, region, pais)
  VALUES
    (1, 'San Cristóbal', 'Táchira', 'Andes', 'Venezuela'),
    (2, 'Valencia', 'Carabobo', 'Centro', 'Venezuela'),
    (3, 'Maracaibo', 'Zulia', 'Occidente', 'Venezuela'),
    (4, 'Caracas', 'Distrito Capital', 'Capital', 'Venezuela'),
    (5, 'Barquisimeto', 'Lara', 'Centro', 'Venezuela');

  -- 5. Llenar fact_venta_producto
  INSERT INTO fact_venta_producto (id_dim_cliente, id_dim_producto, cantidad_vendida)
  SELECT
    f.id_cliente,
    fp.id_producto,
    SUM(fp.cantidad)
  FROM factura_producto fp
  JOIN factura f ON f.id = fp.id_factura
  GROUP BY f.id_cliente, fp.id_producto;

  -- 6. Llenar fact_visita
  INSERT INTO fact_visita (id_dim_cliente, id_dim_fecha, dias_desde_ultima_compra)
  SELECT 
    c.id,
    df.id,
    DATEDIFF(f.fecha, COALESCE(
      (SELECT MAX(f2.fecha) 
       FROM factura f2 
       WHERE f2.id_cliente = c.id AND f2.fecha < f.fecha),
      f.fecha))
  FROM factura f
  JOIN cliente c ON c.id = f.id_cliente
  JOIN dim_fecha df ON df.fecha = f.fecha;

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
    SUM(fp.cantidad * p.precio) AS monto_total_vendido,
    ROUND(SUM(fp.cantidad * p.precio) * 0.10, 2) AS monto_descuento, -- 10% descuento ficticio
    ROUND(AVG(p.precio), 2) AS min_promedio_venta_producto
  FROM factura f
  JOIN factura_producto fp ON f.id = fp.id_factura
  JOIN producto p ON p.id = fp.id_producto
  JOIN dim_fecha df ON df.fecha = f.fecha
  GROUP BY df.id, p.id;

END $$

DELIMITER ;



CALL llenar_dimensiones_hechos();

SELECT * FROM DIM_producto;
SELECT * FROM dim_fecha;
SELECT * FROM dim_sucursal;
SELECT * FROM dim_cliente;
SELECT * FROM fact_visita;
SELECT * FROM fact_venta_producto;
SELECT * FROM FACT_ventaCombos;

-- Limpiar dimensiones y hechos
/*
DROP TABLE DIM_producto;
DROP TABLE dim_fecha;
DROP TABLE dim_sucursal;
DROP TABLE dim_cliente;
DROP TABLE fact_visita;
DROP TABLE fact_venta_producto;
DROP TABLE FACT_ventaCombos;
/*