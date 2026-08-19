# Hospital Patient Visits Analysis (MySQL)

An end-to-end SQL project: designing a relational schema, loading multi-year
data, cleaning it, and answering business questions with exploratory analysis.
Built as a practice project using a synthetic hospital dataset (no real
patient data).

## Dataset

A simulated hospital operations database covering 2020-2025:

| Table | Rows | Description |
|---|---|---|
| `Dim_Patient` | 2,436 | Patient demographics |
| `Dim_Doctor` | 200 | Doctor roster |
| `Dim_Department` | 40 | Hospital departments |
| `Dim_Diagnosis` | 40 | Diagnosis codes |
| `Dim_Treatment` | 30 | Treatment/procedure codes |
| `Dim_PaymentMethod` | 4 | Payment method lookup |
| `PatientVisits` (2020-2025, combined) | 16,543 | Visit-level fact table: dates, billing, insurance, satisfaction, wait time |

## What I did

1. **Schema design** (`sql/01_schema.sql`) — 6 dimension tables + 4 yearly
   visit fact tables, joined with foreign keys.
2. **Data load** (`sql/02_data_load.sql`) — populated all tables.
3. **Data cleaning** (`sql/03_data_cleaning.sql`):
   - Dropped patient records with missing `FirstName` (5 rows — placeholder
     "dummy" records seeded in the raw data).
   - Standardized names to proper case and merged `FirstName`/`LastName`
     into a single `FullName` column.
   - Normalized inconsistent gender values (`M`/`F`/`Male`/`Female` → `Male`/`Female`).
   - Split a single `CityStateCountry` free-text field into separate `City`,
     `State`, `Country` columns.
   - Dropped department records missing a category (7 rows), and consolidated
     redundant name fields down to one `DepartmentName`.
   - Merged 4 separate yearly visit tables into one unified `PatientVisits`
     fact table (16,543 rows total).
4. **Exploratory analysis** (`sql/04_exploratory_analysis.sql`) — answered
   3 business questions plus a couple of extras, detailed below.

## Key findings

- **Doctor workload is well-balanced.** Across 200 doctors, distinct patients
  treated ranges roughly 50-108, with no single doctor carrying a
  disproportionate share — the top doctor (Dr. Vikram Singh) treated 108
  distinct patients.
- **UPI is the dominant payment method**, covering 5,404 of 16,543 visits
  (33%) and ~₹496M in revenue — noticeably ahead of Debit Card, Credit Card,
  and Cash, which are close to evenly split (~₹332-340M each).
- **Age isn't a strong driver of bill amount.** Average bill stays in a
  fairly tight ₹88K-94K band across all age groups, with the 66+ group only
  marginally higher than 0-17.
- **Service snapshot:** average wait time is 56.5 minutes and average
  patient satisfaction is 3.62/5 across all visits — a reasonable starting
  point for a "what's dragging satisfaction down" follow-up analysis (e.g.
  wait time vs. satisfaction correlation, or satisfaction by department).

## Tools

MySQL (schema design, joins, aggregation, string cleaning, CASE logic).

## How to run

Run the files in order against a MySQL 8+ instance:
```
mysql -u <user> -p < sql/01_schema.sql
mysql -u <user> -p < sql/02_data_load.sql
mysql -u <user> -p < sql/03_data_cleaning.sql
mysql -u <user> -p < sql/04_exploratory_analysis.sql
```
