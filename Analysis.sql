============================================================
-- RCM DENIALS SQL ANALYSIS
-- File: analysis.sql
-- Purpose: Analyze denial performance, root causes, trends,
--          and reconcile all reported totals.
-- ============================================================


-- ============================================================
-- A. DATA QUALITY
-- Business question:
-- Is the claims data complete, consistent, and correctly mapped
-- before we use it for business reporting?
-- ============================================================


-- A1. Row Counts
select
	(select count(*) from claims) as claims_rows,
	(select count(*) from payers) as payer_rows,
	(select count(*) from denial_codes) as denial_code_rows;

-- A2. Unmapped payers
-- Identifies claims whose payer does not exist in the payer reference table.

select c.payer, count(*) as claim_count
from claims c
left join payers p
	on c.payer = p.payer
where p.payer is null
group by c.payer
order by claim_count desc;

-- A3. Unmapped denial codes
-- Identifies denial codes appearing in claims but missing
-- from the denial-code reference table.

select 
	c.denial_code,
	count(*) as claim_count
from claims c
left join denial_codes dc 
	on c.denial_code  = dc.denial_code 
where c.denial_code  is not null
	and dc.denial_code is  null
group by c.denial_code 
order by claim_count desc;

-- A4. Duplicate claim IDs
-- Claim IDs should uniquely identify each claim.

select claim_id , count(*) as claim_count 
from claims
group by claim_id
having count(*) > 1;

-- A5. Paid amount greater than billed amount
-- Identifies financially impossible or suspicious payment records.

select claim_id, payer, billed_amt , paid_amt 
from claims
where paid_amt > billed_amt
order by claim_id;

-- ============================================================
-- B. EXECUTIVE KPIs
-- Business question:
-- What is the overall financial and denial performance of
-- the claims population?
-- ============================================================

select 
	count(*) as total_claims,
	sum(billed_amt ) as total_billed_amt,
	sum(paid_amt) as total_paid_amt,
	count(*) filter(
		where status = 'Denied'
	) as denied_claims,
	round(
		100.0 *count(*) filter(
			where status = 'Denied'
		)/ count(*),
		1) as "denial_rate_%",
	sum(
		case 
			when status = 'Denied'
			then billed_amt - coalesce(paid_amt,0)
			else 0
		end
	) as "denied_dollars",
	round(
	100.0 * sum(paid_amt) / nullif(sum(billed_amt),0),1
	) as "collection_rate_%"
from claims;

-- ============================================================
-- C. PAYER PERFORMANCE
-- Business question:
-- Which payers are driving denial dollars and how does their
-- denial and collection performance compare?
-- ============================================================

with payer_matrix as
(
select 
	c.payer, 
	count(*) as claims,
	sum(c.billed_amt) as billed,
	sum(c.paid_amt) as paid,
	count(*) filter(
		where c.status = 'Denied'
	) as denied_claims,
	sum(
		case 
			when c.status = 'Denied'
			then c.billed_amt - coalesce(c.paid_amt, 0)
			else 0
		end
	) as denied_dollars
from claims c 
group by c.payer
),
payer_with_mapping as
(
select 
	pm.payer, 
	coalesce(p.payer_type, 'Unmapped') as payer_type,
	pm.claims,
	pm.billed, 
	pm.paid,
	pm.denied_claims, 
	pm.denied_dollars
from payer_matrix pm
left join payers p
	on pm.payer = p.payer
),
payer_ranked as
(
select 
	payer, 
	payer_type,
	round(
		100.0 * denied_claims / nullif(claims,0), 1
	) as denial_rate,
	round(
	100.0 *paid / nullif(billed, 0), 1
	) as collection_rate,
	denied_dollars,
	round(100 * denied_dollars 
	/ nullif(sum(denied_dollars) over(),0),1
	) as "pct_total_denied",
	dense_rank() over(order by denied_dollars desc) denied_dollars_rank
from payer_with_mapping
)
select
	denied_dollars_rank as rank,
	payer, 
	payer_type, 
	denied_dollars, 
	denial_rate,
	pct_total_denied
from payer_ranked;

-- ============================================================
-- D. ROOT CAUSE / PARETO
-- Business question:
-- Which denial categories and denial codes account for the
-- greatest financial impact, and where should remediation
-- efforts be prioritized?
-- ============================================================


-- D1. Denied dollars by category
-- Includes a cumulative percentage for Pareto analysis.

with code_denials as
(
select dc.category ,dc.denial_code, sum(billed_Amt) as denied_charges 
from claims c 
left join denial_codes dc 
	on c.denial_code  = dc.denial_code 
where c.denial_code  is not null
group by dc.category , dc.denial_code
),
code_pareto as
(
select 
	category, 
	denial_code,
	denied_charges,
	round(
	100.0 * denied_charges/sum(denied_charges) over(),1
	) as pct_total_denied,
	round(
		100.0 * sum(denied_charges) over(
		order by denied_charges desc
		rows between unbounded preceding and current row
	)/
	sum(denied_charges) over(),1) as cumilative_pct
from code_denials  
)
select * 
from code_pareto
order by denied_charges desc;

-- ============================================================
-- E. MONTHLY TREND
-- Business question:
-- How are billed and denied dollars changing month over month,
-- and are denial dollars increasing or decreasing?
-- ============================================================

with monthly_matrix as
(
select 
	date_trunc('month', c.service_date )::date as month , 
	sum(c.billed_amt ) as total_billed,
	sum(c.billed_amt) filter(where c.status  = 'Denied') as denied_charges
from claims c 
group by month
),
monthly_with_lag  as (
select 
	month,
	total_billed,
	denied_charges,
	lag(denied_charges) over(order by month) as previous_month_denied,
	denied_charges - lag(denied_charges) over(order by month) as denied_dollars_mom_changed 
from monthly_matrix
)
select 	
	month,
	total_billed,
	denied_charges,
	previous_month_denied ,
	denied_dollars_mom_changed, 
	round(100.0 * denied_dollars_mom_changed / 
			previous_month_denied,1)  as denied_dollars_mom_pct_change 
from monthly_with_lag
order by month;

-- ============================================================
-- F. RECONCILIATION
-- Business question:
-- Do all major reports reconcile to the expected control totals
-- of $18,900 billed and $12,100 denied?
-- ============================================================

-- F1. Overall reconciliation
select 
	sum(c.billed_amt) as reported_billed,
	18900.00 as expected_billed,
	sum(c.billed_amt) - 18900.00 as billed_variance,
	sum(c.billed_amt) filter (where c.status  = 'Denied') as reported_denied,
	12100.00 as expected_denied,
	sum(c.billed_amt) filter (where c.status  = 'Denied') - 12100.00 as denied_variance
from claims c ;

-- F2. Payer report reconciliation
WITH payer_totals AS (

    SELECT
        SUM(
            CASE
                WHEN status = 'Denied'
                THEN billed_amt - COALESCE(paid_amt, 0)
                ELSE 0
            END
        ) AS payer_denied_total,

        SUM(billed_amt) AS payer_billed_total

    FROM claims
)

SELECT
    payer_billed_total,
    18900.00 AS expected_billed,
    payer_billed_total - 18900.00 AS billed_variance,

    payer_denied_total,
    12100.00 AS expected_denied,
    payer_denied_total - 12100.00 AS denied_variance

FROM payer_totals;


-- F3. Root-cause report reconciliation
WITH code_totals AS (

    SELECT
        SUM(
            c.billed_amt - COALESCE(c.paid_amt, 0)
        ) AS code_denied_total

    FROM claims c

    WHERE c.status = 'Denied'
)

SELECT
    code_denied_total,
    12100.00 AS expected_denied,
    code_denied_total - 12100.00 AS denied_variance

FROM code_totals;


-- F4. Monthly trend reconciliation
WITH monthly_totals AS (
    SELECT
        SUM(billed_amt) AS monthly_billed_total,
        SUM(
            CASE
                WHEN status = 'Denied'
                THEN billed_amt - COALESCE(paid_amt, 0)
                ELSE 0
            END
        ) AS monthly_denied_total
    FROM claims
)
SELECT
    monthly_billed_total,
    18900.00 AS expected_billed,
    monthly_billed_total - 18900.00 AS billed_variance,
    monthly_denied_total,
    12100.00 AS expected_denied,
    monthly_denied_total - 12100.00 AS denied_variance
FROM monthly_totals;