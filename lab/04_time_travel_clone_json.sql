/*****************************************************************************************
  Exercise 4 — Time Travel, Zero-Copy Cloning & Semi-Structured Data
  ~15 min  |  The features that make people say "wait, really?"
*****************************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE netco_wh;
USE SCHEMA netco_lab.bronze;


-- =========================================================================
-- 4.1  Zero-copy clone: a full dev copy in seconds
-- =========================================================================

CREATE OR REPLACE TABLE truck_dev CLONE tb_101.raw_pos.truck;

SELECT truck_id, make, model, primary_city FROM truck_dev LIMIT 10;

-- A clone shares the original's storage. You pay only for data you change afterwards.
-- It works for tables, schemas and whole databases:

CREATE OR REPLACE DATABASE tb_101_dev CLONE tb_101;   -- hundreds of millions of rows, in seconds


-- =========================================================================
-- 4.2  Oops: run a bad UPDATE
-- =========================================================================

UPDATE truck_dev SET make = 'OOPS';          -- forgot the WHERE clause!
SET bad_query = LAST_QUERY_ID();

SELECT make, COUNT(*) FROM truck_dev GROUP BY make;   -- everything is 'OOPS'


-- =========================================================================
-- 4.3  Time Travel: query the past, then restore
-- =========================================================================

-- What did the table look like right before the bad statement?
SELECT make, COUNT(*)
FROM truck_dev BEFORE (STATEMENT => $bad_query)
GROUP BY make;

-- Restore it (clone + time travel together)
CREATE OR REPLACE TABLE truck_dev_restored CLONE truck_dev BEFORE (STATEMENT => $bad_query);

SELECT make, COUNT(*) FROM truck_dev_restored GROUP BY make;

-- You can also travel by time:
--   AT (OFFSET => -60*5)           -- 5 minutes ago
--   AT (TIMESTAMP => '...')        -- specific timestamp


-- =========================================================================
-- 4.4  UNDROP
-- =========================================================================

DROP TABLE truck_dev;
SHOW TABLES LIKE 'TRUCK_DEV%';      -- gone
UNDROP TABLE truck_dev;
SHOW TABLES LIKE 'TRUCK_DEV%';      -- back

-- Retention: 1 day by default, up to 90 days on Enterprise edition,
-- followed by 7 days of Fail-safe.


-- =========================================================================
-- 4.5  Semi-structured data: JSON without a pipeline
-- =========================================================================
-- Each menu item has a JSON health-metrics object stored in a VARIANT column:

SELECT menu_item_name, menu_item_health_metrics_obj
FROM netco_lab.bronze.menu
LIMIT 5;

-- Query inside it with : notation and explode arrays with FLATTEN:

SELECT
    m.menu_item_name,
    obj.value:"is_healthy_flag"::STRING     AS is_healthy,
    obj.value:"is_gluten_free_flag"::STRING AS is_gluten_free,
    ing.value::STRING                       AS ingredient
FROM netco_lab.bronze.menu m,
     LATERAL FLATTEN(input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj,
     LATERAL FLATTEN(input => obj.value:"ingredients") ing
WHERE m.truck_brand_name = 'Plant Palace'
LIMIT 20;

-- For tenders: JSON, Avro, Parquet, ORC and XML load natively into VARIANT
-- with no upfront schema. Snowflake stores it in columnar form internally.
