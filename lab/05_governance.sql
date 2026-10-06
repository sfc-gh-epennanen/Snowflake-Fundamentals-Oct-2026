/*****************************************************************************************
  Exercise 5 — Roles & Data Protection (Governance)
  ~10 min  |  Protect personal data with one policy that every tool respects
*****************************************************************************************/

-- The customer_loyalty table contains names, e-mails and phone numbers: GDPR-relevant PII.

-- =========================================================================
-- 5.1  Create an analyst role (RBAC)
-- =========================================================================
-- Snowflake access is role-based: privileges go to roles, and roles go to users.

USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS netco_analyst;

SET my_user = CURRENT_USER();
GRANT ROLE netco_analyst TO USER IDENTIFIER($my_user);

GRANT USAGE ON WAREHOUSE netco_wh TO ROLE netco_analyst;
GRANT USAGE ON DATABASE tb_101 TO ROLE netco_analyst;
GRANT USAGE ON SCHEMA tb_101.raw_customer TO ROLE netco_analyst;
GRANT SELECT ON TABLE tb_101.raw_customer.customer_loyalty TO ROLE netco_analyst;


-- =========================================================================
-- 5.2  Create a masking policy and attach it
-- =========================================================================

CREATE OR REPLACE MASKING POLICY tb_101.governance.mask_pii
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN') THEN val
        ELSE '*** MASKED ***'
    END;

ALTER TABLE tb_101.raw_customer.customer_loyalty
    MODIFY COLUMN e_mail SET MASKING POLICY tb_101.governance.mask_pii;

ALTER TABLE tb_101.raw_customer.customer_loyalty
    MODIFY COLUMN phone_number SET MASKING POLICY tb_101.governance.mask_pii;


-- =========================================================================
-- 5.3  Test it as two different roles
-- =========================================================================

USE ROLE netco_analyst;
USE WAREHOUSE netco_wh;
SELECT first_name, last_name, city, e_mail, phone_number
FROM tb_101.raw_customer.customer_loyalty LIMIT 10;      -- masked

USE ROLE ACCOUNTADMIN;
SELECT first_name, last_name, city, e_mail, phone_number
FROM tb_101.raw_customer.customer_loyalty LIMIT 10;      -- clear text

-- The same query returns different results depending on the role.
-- Power BI, Tableau, dbt, Python and AI agents all get the same enforcement.


-- =========================================================================
-- 5.4  (Optional) Let Snowflake find the PII for you
-- =========================================================================

USE ROLE ACCOUNTADMIN;
SELECT SYSTEM$CLASSIFY('tb_101.raw_customer.customer_loyalty', {'auto_tag': false});

-- Or go to: Catalog → Database Explorer → customer_loyalty → … → Classify

-- For tenders (Horizon Catalog): masking policies, row access policies, tag-based
-- policies, automatic classification, lineage, access history, Trust Center.
-- Everything is defined in SQL, so it can be versioned and deployed with CI/CD.
