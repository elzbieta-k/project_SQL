# Stavanger Housing Market Analysis

## Introduksjon

Dette prosjektet analyserer boligmarkedet i Stavanger basert på to datasett:

- **Apartments dataset:** informasjon om boliger (areal, antall rom, bygningstype, adresse, etc.)

- **Sales dataset:** informasjon om salgstransaksjoner (dato, pris, gjeld, prisantydning, etc.)

**Mål**: Å utforske hvordan faktorer som beliggenhet, boligtype, bygningsår påvirker prisene.
Prosjektet demonstrerer ferdigheter innen SQL Server (T-SQL), dataklargjøring og dataanalyse.

## Datasett

apartments (65,830 rader, 25 kolonner)

market_transactions (88,993 rader, 8 kolonner)

Etter import ble dataene renset og transformert til:

apartments_clean

sales_clean

## Dataklargjøring

Import av CSV med SQL Server Import Wizard

Opprettet raw tables (NVARCHAR for alle kolonner) for å unngå importfeil

Renset data ved å bruke TRY_CAST til riktige datatyper (DATE, INT, FLOAT)

## Datadisklaimer

Datasettet som er brukt i dette prosjektet er levert av "virdi.no" under en avtale.  
Ifølge avtalen kan data kun brukes til skoleoppgave og kan ikke deles offentlig.  

Derfor er ikke de originale datafilene inkludert i dette repoet.  
All kode og spørringer er tilgjengelig her, men analysene kan kun kjøres med de originale filene jeg fikk.

## SQL Queries & Analysis

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

