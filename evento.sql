SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT IF NOT EXISTS evento_llenado_hechos
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '01:00:00')
DO
BEGIN
  CALL llenar_dimensiones_hechos();
END $$

DELIMITER ;

SHOW EVENTS;

SHOW CREATE EVENT evento_llenado_hechos;

