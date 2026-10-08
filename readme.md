# RCM Denials SQL Analysis

## Problem Statement

Healthcare organizations can lose significant revenue when claims are denied, but identifying the highest-impact denial causes and payers requires reliable financial and claims-level analysis. This project uses PostgreSQL to analyze claim denials, quantify denied dollars, identify root causes, evaluate payer performance, and validate that reported results reconcile to the underlying claims data.

## Project Overview

This project demonstrates an end-to-end SQL analysis of a synthetic RCM claims dataset containing:

- 13 claims
- $18,900 total billed
- $5,700 total paid
- $12,100 total denied dollars
- 5 payer records
- 4 denial-code reference records

The analysis focuses on data quality, executive KPIs, payer performance, denial root causes, monthly trends, and financial reconciliation.

---

## Project Structure

```text
rcm-denials-sql-analysis/
│
├── setup.sql
├── analysis.sql
└── findings.md
