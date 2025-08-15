SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE EVENT evento_llenado_hechos
ON SCHEDULE EVERY 1 DAY
STARTS DATE_ADD(CURDATE(), INTERVAL 1 DAY) + INTERVAL 1 HOUR
DO
BEGIN
  CALL llenar_dimensiones_hechos();
END $$

DELIMITER ;

SHOW EVENTS;

SHOW CREATE EVENT evento_llenado_hechos;

