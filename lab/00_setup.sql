/*****************************************************************************************
  Netcompany Norway x Snowflake - Hands-on Snowflake Fundamentals
  00_setup.sql  -  run this ONCE at the start of the lab (takes ~3-6 minutes)

  HOW TO RUN
    1. Snowsight > Projects > Workspaces (or Worksheets) > + > SQL File
    2. Paste this whole file
    3. Click the arrow next to "Run" and choose "Run All"  (Cmd/Ctrl + Shift + Enter)
    4. Keep the tab open - while it loads, the presenter explains the architecture

  WHAT IT CREATES
    Database  TB_101 (Tasty Bytes - fictional global food-truck company)
      RAW_POS        trucks, menus, locations, franchises, orders (hundreds of millions of rows)
      RAW_CUSTOMER   loyalty-programme customers (contains PII - used in the governance exercise)
      RAW_SUPPORT    customer reviews in several languages (used in the AI exercise)
      HARMONIZED     joined views
      ANALYTICS      business-friendly views
      GOVERNANCE     masking policies go here
    Warehouses TB_LOAD_WH (load) and TB_LAB_WH (everything else)

  Source data: Snowflake's public Tasty Bytes quickstart bucket (s3://sfquickstarts/...)
*****************************************************************************************/

USE ROLE ACCOUNTADMIN;

-- Lets Cortex AI functions run even if a model is not hosted in your trial's region
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

USE ROLE SYSADMIN;

-- ---------------------------------------------------------------------------
-- Warehouses (compute). They start suspended and cost nothing until used.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE WAREHOUSE tb_load_wh
    WAREHOUSE_SIZE = 'LARGE'          -- big for the initial load, suspended at the end
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Netcompany lab - initial data load';

CREATE OR REPLACE WAREHOUSE tb_lab_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Netcompany lab - exercises';

-- ---------------------------------------------------------------------------
-- Database and schemas (storage)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE DATABASE tb_101;
CREATE OR REPLACE SCHEMA tb_101.raw_pos;
CREATE OR REPLACE SCHEMA tb_101.raw_customer;
CREATE OR REPLACE SCHEMA tb_101.raw_support;
CREATE OR REPLACE SCHEMA tb_101.harmonized;
CREATE OR REPLACE SCHEMA tb_101.analytics;
CREATE OR REPLACE SCHEMA tb_101.governance;

USE WAREHOUSE tb_load_wh;

-- ---------------------------------------------------------------------------
-- File format + external stage pointing at the public S3 bucket
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT tb_101.public.csv_ff TYPE = 'CSV';

CREATE OR REPLACE STAGE tb_101.public.s3load
    URL = 's3://sfquickstarts/frostbyte_tastybytes/'
    FILE_FORMAT = tb_101.public.csv_ff;

CREATE OR REPLACE STAGE tb_101.public.truck_reviews_s3load
    URL = 's3://sfquickstarts/tastybytes-voc/'
    FILE_FORMAT = tb_101.public.csv_ff;

-- ---------------------------------------------------------------------------
-- Raw tables
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE tb_101.raw_pos.country (
    country_id NUMBER(18,0), country VARCHAR, iso_currency VARCHAR(3), iso_country VARCHAR(2),
    city_id NUMBER(19,0), city VARCHAR, city_population VARCHAR);

CREATE OR REPLACE TABLE tb_101.raw_pos.franchise (
    franchise_id NUMBER(38,0), first_name VARCHAR, last_name VARCHAR, city VARCHAR,
    country VARCHAR, e_mail VARCHAR, phone_number VARCHAR);

CREATE OR REPLACE TABLE tb_101.raw_pos.location (
    location_id NUMBER(19,0), placekey VARCHAR, location VARCHAR, city VARCHAR,
    region VARCHAR, iso_country_code VARCHAR, country VARCHAR);

CREATE OR REPLACE TABLE tb_101.raw_pos.menu (
    menu_id NUMBER(19,0), menu_type_id NUMBER(38,0), menu_type VARCHAR, truck_brand_name VARCHAR,
    menu_item_id NUMBER(38,0), menu_item_name VARCHAR, item_category VARCHAR, item_subcategory VARCHAR,
    cost_of_goods_usd NUMBER(38,4), sale_price_usd NUMBER(38,4),
    menu_item_health_metrics_obj VARIANT);

CREATE OR REPLACE TABLE tb_101.raw_pos.truck (
    truck_id NUMBER(38,0), menu_type_id NUMBER(38,0), primary_city VARCHAR, region VARCHAR,
    iso_region VARCHAR, country VARCHAR, iso_country_code VARCHAR, franchise_flag NUMBER(38,0),
    year NUMBER(38,0), make VARCHAR, model VARCHAR, ev_flag NUMBER(38,0),
    franchise_id NUMBER(38,0), truck_opening_date DATE);

CREATE OR REPLACE TABLE tb_101.raw_pos.order_header (
    order_id NUMBER(38,0), truck_id NUMBER(38,0), location_id FLOAT, customer_id NUMBER(38,0),
    discount_id VARCHAR, shift_id NUMBER(38,0), shift_start_time TIME(9), shift_end_time TIME(9),
    order_channel VARCHAR, order_ts TIMESTAMP_NTZ(9), served_ts VARCHAR, order_currency VARCHAR(3),
    order_amount NUMBER(38,4), order_tax_amount VARCHAR, order_discount_amount VARCHAR,
    order_total NUMBER(38,4));

CREATE OR REPLACE TABLE tb_101.raw_pos.order_detail (
    order_detail_id NUMBER(38,0), order_id NUMBER(38,0), menu_item_id NUMBER(38,0),
    discount_id VARCHAR, line_number NUMBER(38,0), quantity NUMBER(5,0), unit_price NUMBER(38,4),
    price NUMBER(38,4), order_item_discount_amount VARCHAR);

CREATE OR REPLACE TABLE tb_101.raw_customer.customer_loyalty (
    customer_id NUMBER(38,0), first_name VARCHAR, last_name VARCHAR, city VARCHAR, country VARCHAR,
    postal_code VARCHAR, preferred_language VARCHAR, gender VARCHAR, favourite_brand VARCHAR,
    marital_status VARCHAR, children_count VARCHAR, sign_up_date DATE, birthday_date DATE,
    e_mail VARCHAR, phone_number VARCHAR);

CREATE OR REPLACE TABLE tb_101.raw_support.truck_reviews (
    order_id NUMBER(38,0), language VARCHAR, source VARCHAR, review VARCHAR, review_id NUMBER(38,0));

-- ---------------------------------------------------------------------------
-- Load data (COPY INTO = bulk load from the stage)
-- ---------------------------------------------------------------------------
COPY INTO tb_101.raw_pos.country           FROM @tb_101.public.s3load/raw_pos/country/;
COPY INTO tb_101.raw_pos.franchise         FROM @tb_101.public.s3load/raw_pos/franchise/;
COPY INTO tb_101.raw_pos.location          FROM @tb_101.public.s3load/raw_pos/location/;
COPY INTO tb_101.raw_pos.menu              FROM @tb_101.public.s3load/raw_pos/menu/;
COPY INTO tb_101.raw_pos.truck             FROM @tb_101.public.s3load/raw_pos/truck/;
COPY INTO tb_101.raw_customer.customer_loyalty FROM @tb_101.public.s3load/raw_customer/customer_loyalty/;
COPY INTO tb_101.raw_pos.order_header      FROM @tb_101.public.s3load/raw_pos/order_header/;
COPY INTO tb_101.raw_pos.order_detail      FROM @tb_101.public.s3load/raw_pos/order_detail/;
COPY INTO tb_101.raw_support.truck_reviews FROM @tb_101.public.truck_reviews_s3load/raw_support/truck_reviews/;

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW tb_101.harmonized.orders_v AS
SELECT
    oh.order_id, oh.truck_id, oh.order_ts, od.order_detail_id, od.line_number,
    m.truck_brand_name, m.menu_type, t.primary_city, t.region, t.country,
    t.franchise_flag, t.franchise_id,
    f.first_name AS franchisee_first_name, f.last_name AS franchisee_last_name,
    l.location_id, cl.customer_id, cl.first_name, cl.last_name, cl.e_mail, cl.phone_number,
    cl.children_count, cl.gender, cl.marital_status,
    od.menu_item_id, m.menu_item_name, od.quantity, od.unit_price, od.price,
    oh.order_amount, oh.order_tax_amount, oh.order_discount_amount, oh.order_total
FROM tb_101.raw_pos.order_detail od
JOIN tb_101.raw_pos.order_header oh ON od.order_id = oh.order_id
JOIN tb_101.raw_pos.truck t         ON oh.truck_id = t.truck_id
JOIN tb_101.raw_pos.menu m          ON od.menu_item_id = m.menu_item_id
JOIN tb_101.raw_pos.franchise f     ON t.franchise_id = f.franchise_id
JOIN tb_101.raw_pos.location l      ON oh.location_id = l.location_id
LEFT JOIN tb_101.raw_customer.customer_loyalty cl ON oh.customer_id = cl.customer_id;

CREATE OR REPLACE VIEW tb_101.analytics.orders_v
    COMMENT = 'Tasty Bytes order detail - one row per order line'
AS
SELECT DATE(o.order_ts) AS date, * FROM tb_101.harmonized.orders_v o;

CREATE OR REPLACE VIEW tb_101.harmonized.truck_reviews_v AS
SELECT DISTINCT
    r.review_id, r.order_id, oh.truck_id, r.language, r.source, r.review,
    t.primary_city, oh.customer_id, TO_DATE(oh.order_ts) AS date, m.truck_brand_name
FROM tb_101.raw_support.truck_reviews r
JOIN tb_101.raw_pos.order_header oh ON oh.order_id = r.order_id
JOIN tb_101.raw_pos.truck t         ON t.truck_id = oh.truck_id
JOIN tb_101.raw_pos.menu m          ON m.menu_type_id = t.menu_type_id;

CREATE OR REPLACE VIEW tb_101.analytics.truck_reviews_v AS
SELECT * FROM tb_101.harmonized.truck_reviews_v;

-- ---------------------------------------------------------------------------
-- Finish: shut the big warehouse down, switch to the small one
-- ---------------------------------------------------------------------------
ALTER WAREHOUSE tb_load_wh SUSPEND;
USE WAREHOUSE tb_lab_wh;

-- Sanity check - you should see row counts for every table
SELECT 'country' AS table_name, COUNT(*) AS row_count FROM tb_101.raw_pos.country
UNION ALL SELECT 'franchise',        COUNT(*) FROM tb_101.raw_pos.franchise
UNION ALL SELECT 'location',         COUNT(*) FROM tb_101.raw_pos.location
UNION ALL SELECT 'menu',             COUNT(*) FROM tb_101.raw_pos.menu
UNION ALL SELECT 'truck',            COUNT(*) FROM tb_101.raw_pos.truck
UNION ALL SELECT 'customer_loyalty', COUNT(*) FROM tb_101.raw_customer.customer_loyalty
UNION ALL SELECT 'order_header',     COUNT(*) FROM tb_101.raw_pos.order_header
UNION ALL SELECT 'order_detail',     COUNT(*) FROM tb_101.raw_pos.order_detail
UNION ALL SELECT 'truck_reviews',    COUNT(*) FROM tb_101.raw_support.truck_reviews
ORDER BY row_count DESC;
