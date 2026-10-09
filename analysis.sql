-- ============================================================
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
			then billed_amt
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
with payer_stats as
(
select 
	c.payer, 
	coalesce(p.payer_type, 'Unmapped') as payer_type,
	sum(c.billed_amt) total_billed,
	sum(c.paid_amt) as total_paid,
	sum(c.billed_amt) filter(where c.status = 'Denied' ) as denied_dollars
from claims c
left join payers p 
	on c.payer = p.payer
group by c.payer, payer_type
)
select payer,
round(100.0 *denied_dollars / total_billed,1) as denial_rate,
round(100.0* total_paid / total_billed,1) as collection_rate,
denied_dollars,
round(100.0 *denied_dollars /sum(denied_dollars) over(),1) as pct_total_denied,
dense_rank() over(order by denied_dollars desc) ranked_denials
from payer_stats;

-- ============================================================
-- D. ROOT CAUSE / PARETO ANALYSIS
-- Business question:
-- Which denial categories and denial codes create the greatest
-- financial impact, and which denial causes should be prioritized?
-- ============================================================


-- ============================================================
-- D1. DENIED DOLLARS BY CATEGORY
-- Business question:
-- Which denial categories account for the largest share of
-- total denied dollars?
-- ============================================================

WITH category_report AS (

    SELECT
        COALESCE(dc.category, 'Unmapped') AS category,

        SUM(
            c.billed_amt - COALESCE(c.paid_amt, 0)
        ) AS denied_dollars

    FROM claims AS c

    LEFT JOIN denial_codes AS dc
        ON c.denial_code = dc.denial_code

    WHERE c.status = 'Denied'

    GROUP BY
        COALESCE(dc.category, 'Unmapped')
),

category_pareto AS (

    SELECT
        category,
        denied_dollars,

        ROUND(
            100.0 * denied_dollars
            / NULLIF(
                SUM(denied_dollars) OVER (),
                0
            ),
            1
        ) AS pct_total_denied,

        ROUND(
            100.0 *
            SUM(denied_dollars) OVER (
                ORDER BY denied_dollars DESC
                ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
            )
            / NULLIF(
                SUM(denied_dollars) OVER (),
                0
            ),
            1
        ) AS cumulative_pct

    FROM category_report
)

SELECT
    category,
    denied_dollars,
    pct_total_denied,
    cumulative_pct
FROM category_pareto
ORDER BY denied_dollars DESC;


-- ============================================================
-- D2. DENIED DOLLARS BY DENIAL CODE
-- Business question:
-- Which individual denial codes contribute the most denied
-- dollars, and how quickly do the highest-impact codes reach
-- the Pareto 80% threshold?
-- ============================================================

WITH code_report AS (
    SELECT
        c.denial_code,
        COALESCE(
            dc.description,
            'Unmapped'
        ) AS description,
        COALESCE(
            dc.category,
            'Unmapped'
        ) AS category,
        SUM(
            c.billed_amt - COALESCE(c.paid_amt, 0)
        ) AS denied_dollars
    FROM claims AS c
    LEFT JOIN denial_codes AS dc
        ON c.denial_code = dc.denial_code
    WHERE c.status = 'Denied'
    GROUP BY
        c.denial_code,
        dc.description,
        dc.category
),
code_pareto AS (
    SELECT
        denial_code,
        description,
        category,
        denied_dollars,
        ROUND(
            100.0 * denied_dollars
            / NULLIF(
                SUM(denied_dollars) OVER (),
                0
            ),
            1
        ) AS pct_total_denied,
        ROUND(
            100.0 *
            SUM(denied_dollars) OVER (
                ORDER BY denied_dollars DESC
                ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
            )
            / NULLIF(
                SUM(denied_dollars) OVER (),
                0
            ),
            1
        ) AS cumulative_pct
    FROM code_report
)
SELECT
    denial_code,
    description,
    category,
    denied_dollars,
    pct_total_denied,
    cumulative_pct
FROM code_pareto
ORDER BY denied_dollars DESC;
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
   with payer_report as (
     select payer,
            sum(billed_amt) as billed,
            sum(billed_amt) filter (where status = 'Denied') as denied
     from claims group by payer
   )
   select sum(billed) as reported_billed, sum(billed) - 18900 as billed_variance,
          sum(denied) as reported_denied, sum(denied) - 12100 as denied_variance
   from payer_report;