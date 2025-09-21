-- Dataklargjøring
-- 1. Import av CSV med SQL Server Import Wizard
-- 2. Opprettet raw tables (NVARCHAR for alle kolonner) for å unngå importfeil
-- 3. Renset data ved å bruke TRY_CAST til riktige datatyper (DATE, INT, FLOAT)


--Sjekke data
SELECT TOP 100 * FROM apartments
SELECT TOP 100 * FROM market_transactions
SELECT * FROM sales_clean
WHERE register_date <> '1900-01-01'

CREATE TABLE apartments_clean (
    id INT PRIMARY KEY,
    etablertdato DATE NULL,
    tattibrukdato DATE NULL,
    eiendomareal FLOAT NULL,
    bygningstype NVARCHAR(100) NULL,
    prom FLOAT NULL,
    bruksaerealbruksenhet FLOAT NULL,
    bruksarealbolig FLOAT NULL,
    harheis NVARCHAR(10) NULL,
    antallrom INT NULL,
    antallbad INT NULL,
    antallwc INT NULL,
    street_address NVARCHAR(255) NULL,
    coord_x FLOAT NULL,
    coord_y FLOAT NULL,
    kommunenr INT NULL,
    grunnkrets NVARCHAR(100) NULL,
    postnr INT NULL,
    unit_type NVARCHAR(100) NULL,
    parkering NVARCHAR(100) NULL,
	balkong NVARCHAR(100) NULL,
	soverom INT NULL,
	antalletasjer INT NULL,
    heating_score FLOAT NULL,
    energy_score NVARCHAR(20) NULL
);

INSERT INTO apartments_clean
SELECT
    CAST(id AS INT),
    TRY_CAST(etablertdato AS DATE),
    TRY_CAST(tattibrukdato AS DATE),
    TRY_CAST(eiendomareal AS FLOAT),
    bygningstype,
    TRY_CAST(prom AS FLOAT),
    TRY_CAST(bruksaerealbruksenhet AS FLOAT),
    TRY_CAST(bruksarealbolig AS FLOAT),
    harheis,
    TRY_CAST(antallrom AS INT),
    TRY_CAST(antallbad AS INT),
    TRY_CAST(antallwc AS INT),
    street_address,
    TRY_CAST(coord_x AS FLOAT),
    TRY_CAST(coord_y AS FLOAT),
    TRY_CAST(kommunenr AS INT),
    grunnkrets,
    TRY_CAST(postnr AS INT),
    unit_type,
    parkering,
	balkong,
	TRY_CAST(soverom AS INT),
	TRY_CAST(antalletasjer AS INT),
    TRY_CAST(heating_score AS FLOAT),
    energy_score
FROM dbo.apartments;

CREATE TABLE sales_clean (
    id INT PRIMARY KEY,
    address_id INT,
    register_date DATE NULL,
    sold_date DATE NULL,
    official_date DATE NULL,
    official_price FLOAT NULL,
    common_debt FLOAT NULL,
    asking_price FLOAT NULL
);


INSERT INTO sales_clean
SELECT
    id,
    address_id,
    TRY_CAST(register_date AS DATE),
    TRY_CAST(sold_date AS DATE),
    TRY_CAST(official_date AS DATE),
    TRY_CAST(official_price AS FLOAT),
    TRY_CAST(common_debt AS FLOAT),
    TRY_CAST(asking_price AS FLOAT)
FROM market_transactions;


-----------ANALYSE--------------

--Hvor mange leiligheter er registrert totalt
SELECT COUNT(*) AS total_apartments
FROM apartments_clean


--Antall boliger per bygninstype
SELECT
bygningstype,
COUNT(id) as antall_boliger
FROM apartments_clean
GROUP BY bygningstype
ORDER BY antall_boliger DESC

--Lage view med join tabeller (siden det er brukt flere ganger - slipper å skrive samme JOIN flere ganger)

DROP VIEW IF EXISTS sales_with_apartments;
GO

CREATE VIEW sales_with_apartments AS
SELECT 
	s.id AS sale_id,
	s.address_id,
	s.official_date,
	s.official_price,
	a.street_address,
	a.postnr,
	a.bygningstype,
	a.antallrom,
	a.bruksarealbolig,
	a.tattibrukdato,
	a.balkong,
	a.prom
FROM sales_clean s
JOIN apartments_clean a ON s.address_id = a.id


--Gjennomsnitt pris for bygningstype
SELECT 
	bygningstype,
	ROUND(AVG(official_price), 0) AS gjennomsnitt_pris
FROM sales_with_apartments
WHERE official_price IS NOT NULL
GROUP BY bygningstype

--Sesongtrender (salg per måned)
SELECT 
	YEAR(s.official_date) as år,
	MONTH(s.official_date) as måned,
	COUNT(*) as antall_salg,
	ROUND(AVG(s.official_price),0) as snitt_pris
FROM sales_clean s
WHERE s.official_price IS NOT NULL AND s.official_price <> '0'
GROUP BY YEAR(s.official_date), MONTH(s.official_date)
ORDER BY antall_salg DESC


--Antall salg per år
SELECT 
YEAR(official_date) AS salg_år,
COUNT(*) AS antall_salg
FROM sales_clean
GROUP BY YEAR(official_date)
ORDER BY antall_salg DESC


--Balkong vs. pris
SELECT 
balkong,
ROUND(AVG(official_price), 2) as gjennomsnitt_pris
FROM sales_with_apartments
GROUP BY balkong

--Endring av boligpriser over tid
SELECT 
	YEAR(official_date) as år,
	ROUND(AVG(official_price), 0) as snitt_pris
FROM sales_with_apartments
WHERE official_price IS NOT NULL AND official_price <> '0'
GROUP BY YEAR(official_date)
ORDER BY år


--Gjennomsnitt tid i dager som tar å selge en bolig av ulike bygninstyper
SELECT 
	a.bygningstype,
	AVG(DATEDIFF(day, s.register_date, s.sold_date)) as snitt_dager_av_salg
FROM sales_clean s
JOIN apartments_clean a ON s.address_id = a.id
WHERE register_date <> '1900-01-01' AND sold_date <> '1900-01-01'
GROUP BY bygningstype

--Boliger solgte flere ganger - 
SELECT s.address_id,
COUNT(*) AS antall_salg
FROM sales_clean s
WHERE s.official_date IS NOT NULL
GROUP BY s.address_id
HAVING COUNT(*) > 1
ORDER BY antall_salg DESC


--Utvikling av pris for hver bolig over tid
SELECT 
	address_id,
	street_address,
	official_date,
	official_price
FROM sales_with_apartments
WHERE official_price IS NOT NULL
ORDER BY address_id, official_date


--Beregne prisendring mellom første og siste salg
WITH ranked_sales AS (
SELECT
address_id,
street_address,
official_date,
official_price,
ROW_NUMBER () OVER (PARTITION BY address_id ORDER BY official_date ASC) AS ranked_sales_asc,
ROW_NUMBER () OVER (PARTITION BY address_id ORDER BY official_date DESC) AS ranked_sales_desc
FROM sales_with_apartments
WHERE official_price IS NOT NULL AND official_price <> '0'
)
SELECT 
	first_sale.address_id,
	first_sale.street_address,
	first_sale.official_date AS first_date,
	first_sale.official_price AS first_price,
	last_sale.official_date AS last_date,
	last_sale.official_price AS last_price,
	(last_sale.official_price - first_sale.official_price) AS pris_endring,
	ROUND((last_sale.official_price - first_sale.official_price) * 100.0 / first_sale.official_price,2) as prosent_endring,
	DATEDIFF(year, first_sale.official_date, last_sale.official_date) as tid_year
FROM ranked_sales first_sale
JOIN ranked_sales last_sale
ON first_sale.address_id = last_sale.address_id
WHERE first_sale.ranked_sales_asc = 1 AND last_sale.ranked_sales_desc = 1
ORDER BY prosent_endring DESC


--Gjennomsnitt pris per postnummer (med navnet på bydel)

SELECT 
	postnr,
	CASE
		WHEN postnr IN (4005, 4008, 4009, 4010, 4022, 4023, 4024) THEN 'Eiganes og Våland'
		WHEN postnr IN (4006, 4012, 4013, 4014, 4015, 4076) THEN 'Storhaug'
		WHEN postnr IN (4016, 4017, 4019, 4021) THEN 'Hillevåg'
		WHEN postnr IN (4018, 4020, 4031, 4032, 4033, 4034) THEN 'Hinna'
		WHEN postnr IN (4025, 4026, 4027, 4028, 4029, 4154) THEN 'Tasta'
		WHEN postnr IN (4041, 4042, 4043, 4044, 4045, 4046, 4047, 4048, 4049) THEN 'Madla'
		WHEN postnr IN (4077, 4083, 4085) THEN 'Hundvåg'
		ELSE 'Ukjent'
	END as bydel,
	COUNT(sale_id) as antall_salg,
	ROUND(AVG(official_price), 0) AS gjennomsnitt_pris
FROM sales_with_apartments
WHERE postnr IS NOT NULL
GROUP BY postnr
ORDER BY gjennomsnitt_pris DESC



--Sammenheng mellom byggeår og boligpris
SELECT 
    CASE 
        WHEN YEAR(tattibrukdato) < 1950 THEN 'Før 1950'
        WHEN YEAR(tattibrukdato) BETWEEN 1950 AND 1980 THEN '1950–1980'
        WHEN YEAR(tattibrukdato) BETWEEN 1981 AND 2000 THEN '1981–2000'
        WHEN YEAR(tattibrukdato) BETWEEN 2001 AND 2015 THEN '2001–2015'
        ELSE '2016+'
    END AS byggeperiode,
    COUNT(sale_id) AS antall_salg,
    ROUND(AVG(official_price),0) AS gjennomsnitt_pris
FROM sales_with_apartments
WHERE tattibrukdato IS NOT NULL
GROUP BY 
    CASE 
        WHEN YEAR(tattibrukdato) < 1950 THEN 'Før 1950'
        WHEN YEAR(tattibrukdato) BETWEEN 1950 AND 1980 THEN '1950–1980'
        WHEN YEAR(tattibrukdato) BETWEEN 1981 AND 2000 THEN '1981–2000'
        WHEN YEAR(tattibrukdato) BETWEEN 2001 AND 2015 THEN '2001–2015'
        ELSE '2016+'
    END
ORDER BY gjennomsnitt_pris DESC;

