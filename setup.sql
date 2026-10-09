-- ============================================================
-- RCM DENIALS SQL ANALYSIS
-- Database: rcm_denials
-- Purpose: Set up the tables and data for RCM denial analysis
-- ============================================================


-- ============================================================
-- 1. DROP EXISTING TABLES
-- ============================================================

DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS payers;
DROP TABLE IF EXISTS denial_codes;


-- ============================================================
-- 2. CREATE CLAIMS TABLE
-- ============================================================

CREATE TABLE claims (
    claim_id INT PRIMARY KEY,
    payer TEXT NOT NULL,
    billed_amt NUMERIC NOT NULL,
    paid_amt NUMERIC,
    denial_code TEXT,
    status TEXT,
    service_date DATE NOT NULL
);


-- ============================================================
-- 3. CREATE PAYERS TABLE
-- ============================================================

CREATE TABLE payers (
    payer TEXT PRIMARY KEY,
    payer_type TEXT
);


-- ============================================================
-- 4. CREATE DENIAL CODES TABLE
-- ============================================================

CREATE TABLE denial_codes (
    denial_code TEXT PRIMARY KEY,
    description TEXT,
    category TEXT
);


-- ============================================================
-- 5. INSERT CLAIMS
-- ============================================================

INSERT INTO claims (
    claim_id,
    payer,
    billed_amt,
    paid_amt,
    denial_code,
    status,
    service_date
)
VALUES
    (1,  'Aetna',    1200,  900,  NULL,     'Paid',   '2026-01-08'),
    (2,  'Cigna',     800,    0,  'CO-4',   'Denied', '2026-01-20'),
    (3,  'Medicare', 2500,    0,  'CO-197', 'Denied', '2026-02-03'),
    (4,  'Aetna',     600,  600,  NULL,     'Paid',   '2026-02-15'),
    (5,  'UHC',      1500,    0,  'CO-4',   'Denied', '2026-02-27'),
    (6,  'UHC',       900,  700,  NULL,     'Paid',   '2026-03-05'),
    (7,  'Cigna',    1800,    0,  'CO-197', 'Denied', '2026-03-18'),
    (8,  'Medicare', 3000, 2400,  NULL,     'Paid',   '2026-03-29'),
    (9,  'Aetna',    2200,    0,  'CO-4',   'Denied', '2026-04-09'),
    (10, 'UHC',       700,    0,  'CO-16',  'Denied', '2026-04-21'),
    (11, 'Cigna',    1100, 1100,  NULL,     'Paid',   '2026-05-06'),
    (12, 'Medicare', 1600,    0,  'CO-4',   'Denied', '2026-05-19'),
    (13, 'BCBS',      1000,    0,  'CO-16',  'Denied', '2026-05-30');


-- ============================================================
-- 6. INSERT PAYERS
-- ============================================================

INSERT INTO payers (
    payer,
    payer_type
)
VALUES
    ('Aetna',    'Commercial'),
    ('Cigna',    'Commercial'),
    ('UHC',      'Commercial'),
    ('Medicare', 'Government'),
    ('Humana',   'Commercial');


-- ============================================================
-- 7. INSERT DENIAL CODES
-- ============================================================

INSERT INTO denial_codes (
    denial_code,
    description,
    category
)
VALUES
    ('CO-4',   'Procedure code inconsistent with modifier', 'Coding'),
    ('CO-16',  'Claim lacks information',                  'Front-end'),
    ('CO-197', 'Precert/authorization absent',             'Authorization'),
    ('CO-45',  'Charge exceeds fee schedule',              'Contractual');


-- ============================================================
-- 8. VALIDATION
-- ============================================================

-- Number of claims
SELECT COUNT(*) AS claim_count
FROM claims;


-- Total billed amount	
SELECT SUM(billed_amt) AS total_billed
FROM claims;


-- Number of payers
SELECT COUNT(*) AS payer_count
FROM payers;


-- Number of denial codes
SELECT COUNT(*) AS denial_code_count
FROM denial_codes;