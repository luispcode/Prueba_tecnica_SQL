-- 0. visualizaciones de tablas y contar registros:

SELECT *
FROM vendedores AS vend;

SELECT *
FROM ventas AS v;

SELECT *
FROM ventas AS v;

SELECT count(*)
FROM ventas as vent;


-- 1. total de ventas agrupadas por mes: 

SELECT EXTRACT(MONTH FROM fecha)AS mes, sum(monto) AS total
FROM ventas
GROUP BY mes
ORDER BY mes ASC;


-- 2. total de ventas por vendedor: 

SELECT nombre AS vendedor, sum(monto) AS totales
FROM vendedores AS vend
INNER JOIN ventas AS vent 
USING (id_vendedor)
GROUP BY vendedor
ORDER BY totales DESC;


-- 3. paises con ventas totales inferiores a 1.000.000:

SELECT DISTINCT p.nombre AS pais
FROM paises AS p
INNER JOIN vendedores AS vend
ON p.id_pais = vend.pais 
INNER JOIN ventas AS vent 
USING(id_vendedor)
WHERE vent.monto::NUMERIC < 1000000;


-- 4. vendedores sin ventas

SELECT vendedores.nombre AS vendedor
FROM vendedores
INNER JOIN ventas
USING(id_vendedor)
WHERE monto:: NUMERIC < 0
OR monto:: NUMERIC IS NULL;


-- 5. ventas hechas por personas de eeuu en marzo 2022:

SELECT monto AS venta, vendedores.nombre AS vendedor
FROM ventas
INNER JOIN vendedores 
USING(id_vendedor)
WHERE vendedores.pais = '1'
AND EXTRACT(MONTH FROM fecha) = 3
AND EXTRACT(YEAR  FROM fecha) = 2022;


-- 6. ventas totales hechas por personal femenino superiores a 5.000.000:

SELECT sum(monto) AS venta_total
FROM vendedores
INNER JOIN ventas
USING (id_vendedor)
WHERE genero = 'femenino' AND monto::NUMERIC >5000000;

-- 7. crear una tabla temporal que contenga la informacion de la tabla ventas, ademas de los datos  de los vendedores y de los paises. Luego, mostrar de esa tabla las ventas  hechas por hombres de sudamerica

-- 7. opcion 1
CREATE TEMPORARY TABLE temp_ventas_1(id_vendedor varchar(150), vendedor varchar(150), genero varchar(150), monto numeric, fecha date, id_pais varchar(150), pais varchar(150), continente varchar(150));

INSERT INTO temp_ventas_1
(SELECT vendedores.id_vendedor, vendedores.nombre, genero, monto, fecha, paises.id_pais, paises.nombre, continente
FROM vendedores
INNER JOIN ventas
using(id_vendedor)
INNER JOIN paises
ON vendedores.pais = paises.id_pais);

SELECT monto
FROM temp_ventas_1
WHERE genero = 'masculino' AND continente = 'sudamerica';

-- 7 opcion 2
CREATE TEMPORARY TABLE temp_ventas2 as(
SELECT vendedores.id_vendedor, vendedores.nombre, genero, monto, fecha, paises.id_pais, paises.nombre AS nombrepais, paises.continente
FROM vendedores
INNER JOIN ventas
USING (id_vendedor)
INNER JOIN paises 
ON vendedores.pais = paises.id_pais);


-- 8. crear una funcion que reciba como parametro un id_pais y retorne el total de ventas de ese pais

CREATE OR REPLACE FUNCTION total_pais(id_ingresado integer) RETURNS NUMERIC AS $$
DECLARE 
res NUMERIC ;

BEGIN
	-----------------------------
	--- Returns the total sales by selected country
	---------------------------
	
	res:= (SELECT sum(monto)
	FROM ventas
	INNER JOIN vendedores
	USING(id_vendedor)
	INNER JOIN paises
	ON paises.id_pais = vendedores.pais
	WHERE id_pais::integer = id_ingresado);
	RETURN res;
			  
END;
$$ language 'plpgsql';

SELECT total_pais(2);


-- 9. crear una funcion que reciba como parametro un id_pais y entregue los valores de la consulta.

-- 9 opcion 1

CREATE OR REPLACE FUNCTION total_pais_tabla2(id_ingresado integer) 
RETURNS TABLE (vendedor varchar(150), venta money, fecha date, pais varchar(150)) AS $$

DECLARE 
rec record ;

BEGIN
	-----------------------------
	--- Returns the values by selected country
	---------------------------
	
	FOR rec IN(SELECT vendedores.nombre AS vendedor, ventas.monto AS venta, ventas.fecha AS fecha,  paises.nombre AS nombrepais
			FROM ventas
			INNER JOIN vendedores
			USING(id_vendedor)
			INNER JOIN paises
			ON paises.id_pais = vendedores.pais
			WHERE id_pais::integer = id_ingresado)
	
	LOOP
		vendedor := rec.vendedor;
		venta := rec.venta;
		fecha := rec.fecha;
		pais := rec.nombrepais;
		
		RETURN NEXT;
	
	END LOOP;
	
			  
END;
$$ language 'plpgsql';

SELECT total_pais_tabla2(1);


-- 9 opcion 2.

CREATE OR REPLACE FUNCTION total_pais_query1(id_ingresado integer) 
RETURNS TABLE (vendedor varchar(150), venta money, fecha date, pais varchar(150)) AS $$

DECLARE 
rec record ;

BEGIN
	-----------------------------
	--- Returns the values by selected country
	---------------------------
	RETURN QUERY
	SELECT vendedores.nombre AS vendedor, ventas.monto AS venta, ventas.fecha AS fecha,  paises.nombre AS nombrepais
	FROM ventas
	INNER JOIN vendedores
	USING(id_vendedor)
	INNER JOIN paises
	ON paises.id_pais = vendedores.pais
	WHERE id_pais::integer = id_ingresado;
	
			  
END;
$$ language 'plpgsql';

SELECT total_pais_query1(1);

