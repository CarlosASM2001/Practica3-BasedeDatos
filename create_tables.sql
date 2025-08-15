create schema practica3final;
USE practica3final;

-- Carlos Alfredo Serrano Molina 28.457.792
-- Axel Orlando Porras Gonzalez 29.545.523


CREATE TABLE producto (
    id BIGINT NOT NULL,
    nombre VARCHAR(55) NOT NULL,
    precio DECIMAL(6,2),
    PRIMARY KEY (id)
);

CREATE TABLE combo (
    id BIGINT NOT NULL,
    nombre VARCHAR(55) NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE combo_producto(
    id_producto BIGINT NOT NULL,
    id_combo BIGINT NOT NULL,
    PRIMARY KEY(id_producto, id_combo),
    FOREIGN KEY (id_producto) REFERENCES producto(id),
    FOREIGN KEY (id_combo) REFERENCES combo(id)
);

CREATE TABLE cliente(
    id BIGINT NOT NULL,
    email VARCHAR(65) NOT NULL,
    nombre VARCHAR(55) NOT NULL,
    sexo CHAR(1) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE factura(
    id BIGINT NOT NULL,
    fecha DATE NOT NULL,
    monto_total DECIMAL(9,2) NOT NULL,
    id_cliente BIGINT NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id)
);

CREATE TABLE factura_producto(
    id BIGINT NOT NULL,
    precio DECIMAL (9,2) NOT NULL,
    descuento DECIMAL (4,2) NOT NULL,
    cantidad INT NOT NULL,
    id_producto BIGINT NOT NULL,
    id_factura BIGINT NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY (id_producto) REFERENCES producto(id),
    FOREIGN KEY (id_factura) REFERENCES factura(id)
);


/*Tabla Dimensiones*/

CREATE TABLE DIM_producto (
    id BIGINT NOT NULL,
    nombre VARCHAR(55) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE DIM_fecha (
    id BIGINT auto_increment NOT NULL,
    fecha DATE NOT NULL,
    dia INT NOT NULL, 
    mes INT NOT NULL,
    anio INT NOT NULL,
    nombre_dia VARCHAR(20) NOT NULL,
    nombre_mes VARCHAR(20) NOT NULL,
    dia_semana INT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_dim_fecha_fecha (fecha)
);

CREATE TABLE DIM_sucursal(
    id BIGINT NOT NULL,
    ciudad VARCHAR(65) NOT NULL,
    estado VARCHAR(65) NOT NULL,
    region VARCHAR(65) NOT NULL,
    pais VARCHAR(65) NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE DIM_cliente (
    id BIGINT PRIMARY KEY,
    nombre VARCHAR(100),
    sexo CHAR(1),
    fecha_nacimiento DATE,
    rango_edad ENUM('nino', 'adulto')
);


/*Tabla de Hechos*/

CREATE TABLE FACT_ventaCombos(
    id BIGINT auto_increment NOT NULL,
    id_DIM_fecha BIGINT NOT NULL, 
    id_DIM_producto BIGINT NOT NULL,
    id_DIM_sucursal BIGINT NOT NULL,
    cantidad_vendido INT NOT NULL,
    monto_total_vendido DECIMAL(9,2) NOT NULL,
    monto_descuento DECIMAL(9,2) NOT NULL,
    min_promedio_venta_producto DECIMAL(9,2) NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(id_DIM_fecha) REFERENCES DIM_fecha(id),
    FOREIGN KEY(id_DIM_producto) REFERENCES DIM_producto(id),
    FOREIGN KEY(id_DIM_sucursal) REFERENCES DIM_sucursal(id)
);

CREATE TABLE FACT_visita(
    id BIGINT auto_increment NOT NULL,
    id_DIM_cliente BIGINT NOT NULL,
	id_DIM_fecha BIGINT NOT NULL,
    dias_desde_ultima_compra INT NULL,
    PRIMARY KEY(id),
    UNIQUE KEY uq_fact_visita_cliente_fecha (id_DIM_cliente, id_DIM_fecha),
    FOREIGN KEY(id_DIM_cliente) REFERENCES DIM_cliente(id),
    FOREIGN KEY(id_DIM_fecha) REFERENCES DIM_fecha(id)
);

CREATE TABLE FACT_venta_producto(
    id BIGINT auto_increment NOT NULL,
    id_DIM_cliente BIGINT NOT NULL,
    id_DIM_producto BIGINT NOT NULL,
    cantidad_vendida INT NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(id_DIM_cliente) REFERENCES DIM_cliente(id),
    FOREIGN KEY(id_DIM_producto) REFERENCES DIM_producto(id)
);

