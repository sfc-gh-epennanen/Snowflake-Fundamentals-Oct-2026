# Exercise 5 — Roles & Data Protection (Governance)

**Time:** ~10 min  |  **Goal:** protect personal data with one policy that every tool respects

[← Exercise 4](exercise-4-time-travel-clone-json.md)  |  [Next: Exercise 6 →](exercise-6-cortex-ai.md)

---

The `customer_loyalty` table contains names, e-mails and phone numbers: GDPR-relevant personal data.

## 5.1 Create an analyst role (RBAC)

Snowflake access is **role-based**: privileges go to roles, and roles go to users.

```sql
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS netco_analyst;

SET my_user = CURRENT_USER();
GRANT ROLE netco_analyst TO USER IDENTIFIER($my_user);

GRANT USAGE ON WAREHOUSE netco_wh TO ROLE netco_analyst;
GRANT USAGE ON DATABASE tb_101 TO ROLE netco_analyst;
GRANT USAGE ON SCHEMA tb_101.raw_customer TO ROLE netco_analyst;
GRANT SELECT ON TABLE tb_101.raw_customer.customer_loyalty TO ROLE netco_analyst;
```

## 5.2 Create a masking policy and attach it

```sql
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
```

## 5.3 Test it as two different roles

```sql
USE ROLE netco_analyst;
USE WAREHOUSE netco_wh;
SELECT first_name, last_name, city, e_mail, phone_number
FROM tb_101.raw_customer.customer_loyalty LIMIT 10;      -- masked

USE ROLE ACCOUNTADMIN;
SELECT first_name, last_name, city, e_mail, phone_number
FROM tb_101.raw_customer.customer_loyalty LIMIT 10;      -- clear text
```

The same query returns different results depending on the role. Power BI, Tableau, dbt, Python and AI agents all get the same enforcement, because the rule lives in the data platform, not in each tool.

## 5.4 (Optional) Let Snowflake find the PII for you

```sql
USE ROLE ACCOUNTADMIN;
SELECT SYSTEM$CLASSIFY('tb_101.raw_customer.customer_loyalty', {'auto_tag': false});
```

Or go to **Catalog → Database Explorer → customer_loyalty → … → Classify**.

> **For tenders (Horizon Catalog):** masking policies, row access policies, tag-based policies, automatic classification, object and column-level lineage, access history (who read which column), Trust Center security scanning. Everything is defined in SQL, so it can be versioned and deployed with CI/CD.

---

**What you learned:** RBAC, dynamic data masking, classification.
