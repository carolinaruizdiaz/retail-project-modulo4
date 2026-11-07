-- CREAR TABLA CATEGORIAS

-- Se incorpora la tabla categorias para cumplir con
-- el nuevo requerimiento del modulo 4.
--
-- Se migran las categorias existentes en productos
-- para conservar los datos de la entrega anterior.
--
-- Luego se agrega una clave foranea que relaciona
-- productos con categorias.

CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
);
INSERT INTO categorias (nombre)
SELECT DISTINCT categoria
FROM productos;

ALTER TABLE productos
ADD COLUMN id_categoria INTEGER;

UPDATE productos p
SET id_categoria = c.id_categoria
FROM categorias c
WHERE p.categoria = c.nombre;

ALTER TABLE productos
ALTER COLUMN id_categoria SET NOT NULL;

ALTER TABLE productos
ADD CONSTRAINT fk_producto_categoria
FOREIGN KEY (id_categoria)
REFERENCES categorias(id_categoria);

-- Rentabilidad por categoria 

-- Esta consulta permite analizar el rendimiento
-- comercial de cada categoria de productos.
--
-- Muestra cuantas unidades se vendieron y cuanto
-- dinero ingreso por cada categoria.
--
-- Esta informacion permite identificar las categorias
-- con mejor desempeño y tomar decisiones sobre compras,
-- promociones y estrategias de ventas.
--
-- Se relacionan ventas, productos y categorias
-- mediante sus respectivas claves foraneas.
--
-- El ingreso total se calcula utilizando la cantidad
-- vendida multiplicada por el precio unitario real
-- registrado en cada venta.

SELECT
    c.nombre AS categoria,
    SUM(v.cantidad) AS unidades_vendidas,
    SUM(v.cantidad * v.precio_unitario) AS ingreso_total
FROM ventas v
INNER JOIN productos p
    ON v.id_producto = p.id_producto
INNER JOIN categorias c
    ON p.id_categoria = c.id_categoria
GROUP BY
    c.id_categoria,
    c.nombre
HAVING SUM(v.cantidad) > 1
ORDER BY ingreso_total DESC;

-- Clientes sin compras

--Esta consulta permite identificar a los clientes
-- que se registraron en el sistema pero que todavia
-- no realizaron ninguna compra.
--
-- Es una informacion importante para el area comercial,
-- ya que permite desarrollar campañas de marketing,
-- promociones y acciones para incentivar la primera
-- compra y aumentar la conversion de clientes.
--
-- Se utiliza LEFT JOIN para conservar todos los
-- clientes aunque no tengan ventas relacionadas.
--
-- COALESCE permite controlar los posibles valores nulos.

SELECT
    c.id_cliente,
    c.nombre,
    c.apellido,
    COALESCE(c.email, 'Sin email') AS email,
    COALESCE(COUNT(v.id_venta), 0) AS cantidad_compras
FROM clientes c
LEFT JOIN ventas v
    ON c.id_cliente = v.id_cliente
GROUP BY
    c.id_cliente,
    c.nombre,
    c.apellido,
    c.email
HAVING COUNT(v.id_venta) = 0
ORDER BY c.apellido;

--Top de compras por cliente 

-- Esta consulta permite conocer cual es el producto
-- que mas veces compro cada cliente y la fecha de
-- su ultima transaccion.
--
-- Esta informacion ayuda a conocer las preferencias
-- de consumo de cada cliente, personalizar ofertas,
-- recomendar productos y desarrollar estrategias
-- de fidelizacion.
--
-- Se relacionan las tablas clientes, ventas y productos.
--
-- La subconsulta correlacionada obtiene el producto
-- mas comprado por cada cliente.
--
-- COUNT(*) cuenta las operaciones de compra de cada
-- producto para cada cliente.
--
-- ORDER BY COUNT(*) DESC ordena de mayor a menor
-- cantidad de compras.
--
-- LIMIT 1 devuelve el producto mas comprado.
--
-- MAX(fecha_venta) permite conocer la ultima
-- transaccion realizada por cada cliente.
-- COALESCE contempla los clientes que todavia
-- no realizaron compras.

SELECT
    c.id_cliente,
    c.nombre || ' ' || c.apellido AS cliente,

    COALESCE(
        (
            SELECT p2.nombre
            FROM ventas v2
            INNER JOIN productos p2
                ON v2.id_producto = p2.id_producto
            WHERE v2.id_cliente = c.id_cliente
            GROUP BY
                p2.id_producto,
                p2.nombre
            ORDER BY COUNT(*) DESC, p2.nombre ASC
            LIMIT 1
        ),
        'Sin compras'
    ) AS producto_mas_comprado,

    MAX(v.fecha_venta) AS ultima_transaccion

FROM clientes c
LEFT JOIN ventas v
    ON c.id_cliente = v.id_cliente
LEFT JOIN productos p
    ON v.id_producto = p.id_producto
GROUP BY
    c.id_cliente,
    c.nombre,
    c.apellido
ORDER BY c.apellido;
