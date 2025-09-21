Stavanger Housing Market Analysis
📌 Introduksjon

Dette prosjektet analyserer boligmarkedet i Stavanger basert på to datasett:

Apartments dataset: informasjon om boliger (areal, antall rom, bygningstype, adresse, etc.)

Sales dataset: informasjon om salgstransaksjoner (dato, pris, gjeld, prisantydning, etc.)

Mål: Å utforske hvordan faktorer som beliggenhet, boligtype, størrelse og utstyr påvirker prisene.
Prosjektet demonstrerer ferdigheter innen SQL Server (T-SQL), dataklargjøring og dataanalyse.

🗂 Datasett

apartments (65,830 rader, 25 kolonner)

market_transactions (88,993 rader, 8 kolonner)

Etter import ble dataene renset og transformert til:

apartments_clean

sales_clean

🔧 Dataklargjøring

Import av CSV med SQL Server Import Wizard

Opprettet raw tables (NVARCHAR for alle kolonner) for å unngå importfeil

Renset data ved å bruke TRY_CAST til riktige datatyper (DATE, INT, FLOAT)
