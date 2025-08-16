USE practica3final;

DELIMITER $$

CREATE PROCEDURE insertar_datos_julio()
BEGIN
  DECLARE v_target_year INT;
  DECLARE v_start_july DATE;
  DECLARE v_end_july DATE;
  DECLARE v_current_day DATE;
  DECLARE v_next_fact_id BIGINT;
  DECLARE v_next_fp_id BIGINT;
  DECLARE v_invoices_for_day INT;
  DECLARE v_lines INT;
  DECLARE v_cli_id BIGINT;
  DECLARE v_prod_id BIGINT;
  DECLARE v_price DECIMAL(9,2);
  DECLARE v_qty INT;
  DECLARE v_discount DECIMAL(4,2);

  -- Determinar el julio más reciente ya transcurrido
  SET v_target_year = YEAR(CURDATE());
  IF MONTH(CURDATE()) <= 7 THEN
    SET v_target_year = v_target_year - 1;
  END IF;

  SET v_start_july = STR_TO_DATE(CONCAT(v_target_year, '-07-01'), '%Y-%m-%d');
  SET v_end_july   = LAST_DAY(v_start_july);
  SET v_current_day = v_start_july;

  -- Asegurar que existan clientes y productos
  IF (SELECT COUNT(*) FROM cliente) = 0 OR (SELECT COUNT(*) FROM producto) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay clientes o productos en tablas operacionales; ejecute llenar_tabla.sql primero.';
  END IF;

  -- Tomar siguientes IDs para evitar colisiones
  SELECT COALESCE(MAX(id), 0) + 1 INTO v_next_fact_id FROM factura;
  SELECT COALESCE(MAX(id), 0) + 1 INTO v_next_fp_id   FROM factura_producto;

  WHILE v_current_day <= v_end_july DO
    -- Cantidad de facturas del día (5 a 12)
    SET v_invoices_for_day = FLOOR(RAND() * 8) + 5;

    WHILE v_invoices_for_day > 0 DO
      -- Cliente aleatorio existente
      SELECT id INTO v_cli_id FROM cliente ORDER BY RAND() LIMIT 1;

      -- Crear factura placeholder (monto_total se actualiza luego)
      INSERT INTO factura (id, fecha, monto_total, id_cliente)
      VALUES (v_next_fact_id, v_current_day, 0, v_cli_id);

      -- Crear de 1 a 5 líneas de productos
      SET v_lines = FLOOR(RAND() * 5) + 1;
      WHILE v_lines > 0 DO
        SELECT id, precio INTO v_prod_id, v_price FROM producto ORDER BY RAND() LIMIT 1;
        SET v_qty = FLOOR(RAND() * 5) + 1;
        SET v_discount = ROUND(RAND() * 5, 2);

        INSERT INTO factura_producto (id, precio, descuento, cantidad, id_producto, id_factura)
        VALUES (v_next_fp_id, v_price, v_discount, v_qty, v_prod_id, v_next_fact_id);

        SET v_next_fp_id = v_next_fp_id + 1;
        SET v_lines = v_lines - 1;
      END WHILE;

      -- Actualizar monto_total de la factura recién creada
      UPDATE factura f
      SET f.monto_total = (
        SELECT COALESCE(SUM((fp.precio * fp.cantidad) - fp.descuento), 0)
        FROM factura_producto fp
        WHERE fp.id_factura = v_next_fact_id
      )
      WHERE f.id = v_next_fact_id;

      SET v_next_fact_id = v_next_fact_id + 1;
      SET v_invoices_for_day = v_invoices_for_day - 1;
    END WHILE;

    -- Ejecutar ETL incremental para el día
    CALL llenar_dimensiones_hechos(v_current_day);

    -- Día siguiente
    SET v_current_day = DATE_ADD(v_current_day, INTERVAL 1 DAY);
  END WHILE;
END $$

DELIMITER ;

-- Ejecutar carga de julio y visualizar algunos resultados
CALL insertar_datos_julio();

-- Verificación rápida
SELECT MIN(fecha) AS min_fecha_julio, MAX(fecha) AS max_fecha_julio, COUNT(*) AS facturas_julio
FROM factura
WHERE MONTH(fecha) = 7 AND YEAR(fecha) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1);

SELECT COUNT(*) AS visitas_cargadas
FROM FACT_visita v
JOIN DIM_fecha d ON d.id = v.id_DIM_fecha
WHERE MONTH(d.fecha) = 7 AND YEAR(d.fecha) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1);