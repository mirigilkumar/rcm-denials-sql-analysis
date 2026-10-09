# RCM Denials SQL Analysis

## Problem Statement

Healthcare organizations can lose significant revenue when claims are denied, but identifying the highest-impact denial causes and payers requires reliable claims and financial analysis. This project uses PostgreSQL to analyze claim denials, identify the major sources of denied dollars, evaluate payer performance, and validate the accuracy of the reported results.

## Project Structure

```text
rcm-denials-sql-analysis/
│
├── setup.sql
├── analysis.sql
├── findings.md
└── README.md
```

| File | Purpose |
|---|---|
| `setup.sql` | Creates the project tables and loads the analysis data |
| `analysis.sql` | Performs data-quality, KPI, payer, root-cause, trend, and reconciliation analysis |
| `findings.md` | Documents the key business findings, recommendations, and limitations |

---

## How to Run

The project is designed to run from a clean PostgreSQL database.

### Step 1 — Run `setup.sql`

Open the `rcm_denials` database in pgAdmin and execute the entire `setup.sql` script.

This script:

- Drops existing project tables if they exist
- Creates the `claims`, `payers`, and `denial_codes` tables
- Inserts the project data
- Runs basic validation checks

### Step 2 — Run `analysis.sql`

After `setup.sql` completes successfully, execute the entire `analysis.sql` script in the same database.

The analysis is organized into six sections covering data quality, executive KPIs, payer performance, denial root causes, monthly trends, and reconciliation.

---

## Analysis Sections

| Section | Business Question |
|---|---|
| **A. Data Quality** | Is the claims data complete, consistent, and correctly mapped before reporting? |
| **B. Executive KPIs** | What is the overall claims, financial, denial, and collection performance? |
| **C. Payer Performance** | Which payers have the greatest denial and financial impact? |
| **D. Root Cause** | Which denial categories and codes create the greatest financial impact? |
| **E. Trend** | How are billed and denied dollars changing month over month? |
| **F. Reconciliation** | Do the reports reconcile to the expected billed and denied control totals? |

---

## Headline Results

### 1. $12,100 in denied dollars

The dataset contains **13 claims** and **$18,900 in billed charges**. Of these claims, **8 are denied**, representing **$12,100 in denied billed dollars** and a **61.5% claim-level denial rate**.

### 2. Two denial codes drive 86.0% of denied dollars

**CO-4** accounts for **$6,100 (50.4%)** of total denied dollars. **CO-197** contributes another **$4,300 (35.5%)**, meaning these two denial codes account for **$10,400 (86.0%)** of the $12,100 total denied dollars.

### 3. Medicare is the largest payer-level dollar risk

Medicare contributes **$4,100 (33.9%)** of total denied dollars from **2 of 3 claims**. Its **66.7% denial rate** ties with Cigna and UHC, but its higher claim values make it the largest payer-level source of denied dollars in this dataset.

---

## Key Control Totals

| Metric | Expected Result |
|---|---:|
| Claims | 13 |
| Total Billed | $18,900 |
| Total Paid | $5,700 |
| Denied Claims | 8 |
| Denial Rate | 61.5% |
| Denied Dollars | $12,100 |
| Collection Rate | 30.2% |

The reconciliation section of `analysis.sql` validates the reports against these control totals.

---

## Detailed Findings

See the detailed business findings and recommendations:

[Read the detailed findings](findings.md)

---

## SQL Techniques Demonstrated

This project demonstrates practical PostgreSQL techniques including:

- Aggregations
- `CASE`
- `FILTER`
- `LEFT JOIN`
- Common Table Expressions (CTEs)
- `COALESCE`
- `NULLIF`
- `ROUND`
- `DATE_TRUNC`
- Window functions
- `RANK()`
- `LAG()`
- Running window sums
- Percent-of-total calculations
- Pareto analysis
- Month-over-month analysis
- Data-quality validation
- Financial reconciliation

---

## Limitations

- The dataset contains only **13 claims**, so percentages and rankings may change substantially with a larger population.
- The data is **synthetic** and does not represent actual payer performance.
- The dataset covers only **January through May 2026**.
- The claims data contains an intentional **BCBS payer-mapping gap** to demonstrate data-quality validation.
- CO-45 exists in the denial-code reference table but is not currently represented in the claims.
- Production use would require validation against larger claims populations, payer contracts, denial definitions, authorization workflows, coding rules, appeal outcomes, and actual recoveries.
