# RCM Denials — Findings

## 1. Denied dollars are concentrated in a small number of denial codes

**What:**  
Denied dollars are highly concentrated in a few denial codes, with **CO-4** representing the largest source of financial impact.

**How big:**  
CO-4 accounts for **$6,100**, or **50.4% of the total $12,100 in denied dollars**. CO-197 contributes another **$4,300**, bringing the cumulative impact of these two codes to **$10,400, or 86.0% of total denied dollars**.

**Why it matters:**  
A small number of denial causes drive most of the financial exposure. Focusing remediation efforts across every denial type equally could dilute resources, while addressing the highest-impact codes could potentially recover a significant portion of denied dollars.

**What to do:**  
Prioritize root-cause analysis and prevention for **CO-4 and CO-197**. Review modifier/coding accuracy for CO-4 and authorization/precertification workflows for CO-197 before investing significant effort in lower-impact denial categories.


---

## 2. Medicare has a lower denial rate but a significant dollar impact

**What:**  
Medicare has a lower claim-level denial rate than the overall portfolio, but its denied dollars remain financially significant because of the larger dollar value of some Medicare claims.

**How big:**  
Medicare has **4 claims**, of which **1 was denied**, giving it a **25.0% denial rate**. That denied claim represents **$1,600 in denied dollars**, or approximately **13.2% of the portfolio's $12,100 total denied dollars**.

**Why it matters:**  
Looking only at denial rate can hide financial exposure. A payer with fewer denied claims can still contribute meaningful denied dollars when individual claims have higher billed amounts.

**What to do:**  
Track both **denial rate and denied dollars** when prioritizing payer performance. For Medicare, investigate the denial associated with **CO-4** and determine whether the issue is isolated or reflects a broader coding/modifier pattern.


---

## 3. The BCBS payer mapping gap creates a data-quality risk

**What:**  
The claims data contains **BCBS**, but BCBS is missing from the payer reference table. The payer reference table contains **Humana**, which does not appear in the current claims data.

**How big:**  
BCBS represents **1 of 13 claims (7.7%)** and **$1,000 of billed charges**. Its claim is denied for **$1,000**, representing approximately **8.3% of total denied dollars**. Because BCBS is unmapped, payer-level reporting may classify this activity as **"Unmapped"** rather than associating it with a valid payer record.

**Why it matters:**  
An unmapped payer can distort payer performance reporting, rankings, and management decisions. If this issue exists in production data at scale, the impact could be substantially larger than the **$1,000** observed here.

**What to do:**  
Resolve the payer master-data mismatch before relying on payer-level reporting. Confirm whether **BCBS should be added to the payer reference table or whether the claim payer value is incorrect**, then apply a consistent payer mapping rule and add validation checks to prevent future unmapped payers.


---

# Limitations

- The analysis contains only **13 claims**, so percentages and rankings can change substantially with a larger population.
- The dataset is **synthetic** and should not be treated as representative of actual payer or denial behavior.
- The current data covers only a limited period from **January through May 2026**.
- The payer mapping contains a known data-quality issue involving **BCBS and Humana**.
- CO-45 exists in the denial-code reference table but has **no claims** in the current dataset.
- Before taking operational action, the analysis should be validated against a larger production population and reconciled with the organization's financial and claims systems.
- Additional validation would be needed for **claim volume, payer contracts, denial definitions, authorization workflows, coding rules, timely filing, appeal outcomes, and actual recoveries**.
- Business decisions should consider both **denial frequency and financial impact**, rather than relying on a single KPI.