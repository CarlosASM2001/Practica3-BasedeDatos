INSERT INTO combo (id, nombre)
VALUES
(1, 'Combo Básico'),
(2, 'Combo Premium'),
(3, 'Combo Familiar');

----------- TABLA TEMPORAL NOMBRES CLIENTES:-----------------
CREATE TEMPORARY TABLE nombres_clientes (
    nombre VARCHAR(55)
);

INSERT INTO nombres_clientes (nombre) VALUES
('Juan Pérez'),
('María Gómez'),
('Carlos López'),
('Ana Torres'),
('Luis Fernández'),
('Sofía Martínez'),
('Miguel Sánchez'),
('Laura Castro'),
('Jorge Díaz'),
('Lucía Romero');

DELIMITER $$

CREATE PROCEDURE insertar_datos_operativos()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE prod_id BIGINT;
  DECLARE fact_id BIGINT;
  DECLARE cli_id BIGINT;
  DECLARE prod_count INT DEFAULT 50;
  DECLARE fact_count INT DEFAULT 50;
  DECLARE cli_count INT DEFAULT 50;
  
  -- Insertar productos
  WHILE i <= prod_count DO
    INSERT INTO producto (id, nombre, precio)
    VALUES (i, CONCAT('Producto ', i), ROUND(RAND() * 100 + 1, 2));
    SET i = i + 1;
  END WHILE;
  
  SET i = 1;
  
  -- Insertar clientes
  WHILE i <= cli_count DO
	BEGIN
		DECLARE nombre_cliente VARCHAR(55);
		SELECT nombre INTO nombre_cliente
		FROM nombres_clientes
		ORDER BY RAND()
		LIMIT 1;

		INSERT INTO cliente (id, email, nombre, sexo, fecha_nacimiento)
		VALUES (
		  i,
		  CONCAT(REPLACE(LOWER(nombre_cliente), ' ', ''), i, '@gmail.com'),
		  nombre_cliente,
		  ELT(FLOOR(RAND()*2)+1, 'M', 'F'),
		  DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 36500) + 3650 DAY)
		);
		SET i = i + 1;
	END;
  END WHILE;

  -- Insertar facturas
  SET i = 1;
  WHILE i <= fact_count DO
    INSERT INTO factura (id, fecha, monto_total, id_cliente)
    VALUES (
      i,
      DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 30) DAY),
      0, -- monto_total se actualizará luego
      FLOOR(RAND() * cli_count) + 1
    );
    SET i = i + 1;
  END WHILE;

  -- Insertar factura_producto (productos aleatorios para facturas)
  SET i = 1;
  WHILE i <= 200 DO
    SET prod_id = FLOOR(RAND() * prod_count) + 1;
    SET fact_id = FLOOR(RAND() * fact_count) + 1;
    
    INSERT INTO factura_producto (id, precio, descuento, cantidad, id_factura, id_producto)
    VALUES (
      i,
      (SELECT precio FROM producto WHERE id = prod_id),
      ROUND(RAND() * 5, 2),
      FLOOR(RAND() * 5) + 1,
      fact_id,
      prod_id
    );
    SET i = i + 1;
  END WHILE;
  
  -- Insertar combo_producto relacionando productos y combos existentes (3 combos)
  DELETE FROM combo_producto;
  SET i = 1;
  WHILE i <= prod_count DO
    INSERT INTO combo_producto (id_producto, id_combo)
    VALUES (
      i,
      CASE
        WHEN i <= prod_count / 3 THEN 1
        WHEN i <= (prod_count * 2) / 3 THEN 2
        ELSE 3
      END
    );
    SET i = i + 1;
  END WHILE;
  
  -- Actualizar monto_total en factura sumando productos
  UPDATE factura f
  JOIN (
    SELECT id_factura, SUM((precio * cantidad) - descuento) AS total
    FROM factura_producto
    GROUP BY id_factura
  ) fp ON f.id = fp.id_factura
  SET f.monto_total = fp.total;
  
END $$

DELIMITER ;



-- llamada
CALL insertar_datos_operativos();
--
-- Vista

select * from cliente;
select * from combo;
select * from combo_producto;
select * from factura;
select * from factura_producto;
select * from producto;
