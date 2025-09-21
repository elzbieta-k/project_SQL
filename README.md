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


