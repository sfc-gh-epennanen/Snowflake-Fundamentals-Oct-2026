/*****************************************************************************************
  Exercise 2 — Databases, Schemas, Tables & Your First Queries
  ~15 min  |  Build your own database from scratch, load a file, query it
*****************************************************************************************/

-- Open a NEW SQL file in Workspaces for this exercise.

-- =========================================================================
-- 2.1  Create your own database, schema and warehouse
-- =========================================================================
-- Snowflake object hierarchy: Account → Database → Schema → Table/View/Stage/Function

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS netco_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60          -- seconds of idle time before it stops billing
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS netco_lab;
CREATE SCHEMA  IF NOT EXISTS netco_lab.bronze;

USE WAREHOUSE netco_wh;
USE SCHEMA netco_lab.bronze;

-- Refresh Database Explorer: your new database and schema appear.


-- =========================================================================
-- 2.2  Point Snowflake at files in cloud storage
-- =========================================================================
-- A "stage" is a pointer to files (internal or S3/Azure Blob/GCS).

CREATE OR REPLACE FILE FORMAT csv_ff TYPE = 'CSV';

CREATE OR REPLACE STAGE tasty_stage
    URL = 's3://sfquickstarts/frostbyte_tastybytes/'
    FILE_FORMAT = csv_ff;

LIST @tasty_stage/raw_pos/menu/;


-- =========================================================================
-- 2.3  Create a table and load it
-- =========================================================================

CREATE OR REPLACE TABLE menu (
    menu_id NUMBER, menu_type_id NUMBER, menu_type VARCHAR, truck_brand_name VARCHAR,
    menu_item_id NUMBER, menu_item_name VARCHAR, item_category VARCHAR, item_subcategory VARCHAR,
    cost_of_goods_usd NUMBER(38,4), sale_price_usd NUMBER(38,4),
    menu_item_health_metrics_obj VARIANT      -- JSON goes straight into a VARIANT column
);

COPY INTO menu FROM @tasty_stage/raw_pos/menu/;

SELECT * FROM menu LIMIT 10;


-- =========================================================================
-- 2.4  Query the menu
-- =========================================================================
-- Which truck brands have the best margin per item?

SELECT
    truck_brand_name,
    COUNT(*)                                        AS menu_items,
    ROUND(AVG(sale_price_usd - cost_of_goods_usd), 2) AS avg_margin_usd
FROM menu
GROUP BY truck_brand_name
ORDER BY avg_margin_usd DESC;

-- Click "Chart" above the result grid to turn it into a bar chart.


-- =========================================================================
-- 2.5  Query the big dataset (once 00_setup.sql has finished)
-- =========================================================================
-- Revenue by country and brand for 2022, across hundreds of millions of rows:

SELECT
    country,
    truck_brand_name,
    ROUND(SUM(price)) AS revenue_usd
FROM tb_101.analytics.orders_v
WHERE YEAR(date) = 2022
GROUP BY ALL
ORDER BY revenue_usd DESC
LIMIT 20;

-- Snowflake-specific SQL worth knowing:

-- GROUP BY ALL, QUALIFY and EXCLUDE: less boilerplate
SELECT country, truck_brand_name, SUM(price) AS revenue
FROM tb_101.analytics.orders_v
WHERE YEAR(date) = 2022
GROUP BY ALL
QUALIFY ROW_NUMBER() OVER (PARTITION BY country ORDER BY revenue DESC) = 1;   -- best brand per country

SELECT * EXCLUDE (e_mail, phone_number) FROM tb_101.raw_customer.customer_loyalty LIMIT 5;
