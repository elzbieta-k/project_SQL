# Stavanger Housing Market Analysis

## Introduksjon

Dette prosjektet analyserer boligmarkedet i Stavanger basert på to datasett:

- **Apartments dataset:** informasjon om boliger (areal, antall rom, bygningstype, adresse, etc.)

- **Sales dataset:** informasjon om salgstransaksjoner (dato, pris, gjeld, prisantydning, etc.)

**Mål**: Å utforske hvordan faktorer som beliggenhet, boligtype, bygningsår påvirker prisene.
Prosjektet demonstrerer ferdigheter innen SQL Server (T-SQL), dataklargjøring og dataanalyse.

## Datasett

- apartments (65,830 rader, 25 kolonner)

- market_transactions (88,993 rader, 8 kolonner)

Etter import ble dataene renset og transformert til:

- apartments_clean

- sales_clean

## Dataklargjøring

- Import av CSV med SQL Server Import Wizard

- Opprettet raw tables (NVARCHAR for alle kolonner) for å unngå importfeil

- Renset data ved å bruke TRY_CAST til riktige datatyper (DATE, INT, FLOAT)

## Datadisklaimer

Datasettet som er brukt i dette prosjektet er levert av "virdi.no" under en avtale.  
Ifølge avtalen kan data kun brukes til skoleoppgave og kan ikke deles offentlig.  

Derfor er ikke de originale datafilene inkludert i dette repoet.  
All kode og spørringer er tilgjengelig her, men analysene kan kun kjøres med de originale filene jeg fikk.

## SQL Queries & Analysis

### Bli kjent med data
```sql
SELECT TOP 10 * FROM apartments_clean
SELECT TOP 10 * FROM sales_clean
```
<img width="1883" height="369" alt="query00" src="https://github.com/user-attachments/assets/5720f228-e634-4594-a15d-128a6fa1a56e" />


### 1. Hvor mange leiligheter er registrert totalt

```sql
SELECT 
  COUNT(*) AS total_apartments
FROM apartments_clean
```
<img width="141" height="44" alt="query1" src="https://github.com/user-attachments/assets/8469d87d-5bbe-4d80-8cc0-951bd9e80a5b" />

### 2. Antall boliger per bygninstype
```sql
SELECT
  bygningstype,
  COUNT(id) as antall_boliger
FROM apartments_clean
GROUP BY bygningstype
ORDER BY antall_boliger DESC
```
<img width="338" height="419" alt="query2" src="https://github.com/user-attachments/assets/c288303e-2a7c-4cff-8196-5d4142879d6b" />

### 3. Lage view med join tabeller (siden det er brukt flere ganger - slipper å skrive samme JOIN flere ganger)
```sql
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
```
<img width="970" height="182" alt="query3" src="https://github.com/user-attachments/assets/ef0e1134-ec85-455b-b680-83566c82f8ec" />

### 4. Sesongtrender (salg per måned)
```sql
SELECT 
	YEAR(s.official_date) as år,
	MONTH(s.official_date) as måned,
	COUNT(*) as antall_salg,
	ROUND(AVG(s.official_price),0) as snitt_pris
FROM sales_clean s
WHERE s.official_price IS NOT NULL AND s.official_price <> '0'
GROUP BY YEAR(s.official_date), MONTH(s.official_date)
ORDER BY antall_salg DESC
```
<img width="254" height="396" alt="query4" src="https://github.com/user-attachments/assets/1e271ae6-c7a6-426e-84a8-36399a55ae93" />

### 5. Endring av boligpriser over tid

```sql
SELECT 
	YEAR(official_date) as år,
	ROUND(AVG(official_price), 0) as snitt_pris
FROM sales_with_apartments
WHERE official_price IS NOT NULL AND official_price <> '0'
GROUP BY YEAR(official_date)
ORDER BY år
```
<img width="129" height="562" alt="query5" src="https://github.com/user-attachments/assets/33a665bf-cd3e-400c-88ef-66f6744637fc" />

### 6. --Gjennomsnitt tid i dager som tar å selge en bolig av ulike bygninstyper

```sql
SELECT 
	a.bygningstype,
	AVG(DATEDIFF(day, s.register_date, s.sold_date)) as snitt_dager_av_salg
FROM sales_clean s
JOIN apartments_clean a ON s.address_id = a.id
WHERE register_date <> '1900-01-01' AND sold_date <> '1900-01-01'
GROUP BY bygningstype
```

<img width="361" height="345" alt="query6" src="https://github.com/user-attachments/assets/c43fb03a-2120-4646-a403-903000a63090" />

### 7. Boliger solgte flere ganger

```sql
SELECT
	s.address_id,
	COUNT(*) AS antall_salg
FROM sales_clean s
WHERE s.official_date IS NOT NULL
GROUP BY s.address_id
HAVING COUNT(*) > 1
ORDER BY antall_salg DESC
```
<img width="171" height="381" alt="query7" src="https://github.com/user-attachments/assets/32503449-c235-4ba3-a481-06e69cfbda66" />

### 8. Utvikling av pris for hver bolig over tid

```sql
SELECT 
	address_id,
	street_address,
	official_date,
	official_price
FROM sales_with_apartments
WHERE official_price IS NOT NULL
ORDER BY address_id, official_date
```
<img width="357" height="346" alt="query8" src="https://github.com/user-attachments/assets/738d6b20-2feb-4824-b82f-95f9a35e0820" />

### 9. Beregne prisendring mellom første og siste salg
```sql
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
	DATEDIFF(year, first_sale.official_date, last_sale.official_date) as tid_år
FROM ranked_sales first_sale
JOIN ranked_sales last_sale
ON first_sale.address_id = last_sale.address_id
WHERE first_sale.ranked_sales_asc = 1 AND last_sale.ranked_sales_desc = 1
ORDER BY prosent_endring DESC
```

<img width="690" height="389" alt="query9" src="https://github.com/user-attachments/assets/b86fcfc3-1383-49ca-975f-547e4e6615be" />

### 10. Gjennomsnitt pris per postnummer (med navnet på bydel)

```sql
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
```
<img width="347" height="800" alt="query10" src="https://github.com/user-attachments/assets/b70cf42e-9392-4649-b5b2-2cacb05d0a1e" />

### 11. Sammenheng mellom byggeår og boligpris

```sql
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
```

<img width="269" height="104" alt="query11" src="https://github.com/user-attachments/assets/4a790b81-8c98-4ba5-b4ee-66275f01d6d3" />
