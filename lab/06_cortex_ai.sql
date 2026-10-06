/*****************************************************************************************
  Exercise 6 — AI Inside the Platform: Cortex AI SQL & Cortex Code
  ~18 min  |  Run LLMs on your data with plain SQL, then let the AI write SQL for you
*****************************************************************************************/

-- Tasty Bytes collects customer reviews in several languages.
-- Let's analyse them WITHOUT the data leaving Snowflake.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE netco_wh;


-- =========================================================================
-- 6.1  Look at the data
-- =========================================================================

SELECT language, COUNT(*) AS reviews
FROM tb_101.analytics.truck_reviews_v
GROUP BY language
ORDER BY reviews DESC;

SELECT truck_brand_name, language, review
FROM tb_101.analytics.truck_reviews_v
LIMIT 10;


-- =========================================================================
-- 6.2  Sentiment, overall and per topic
-- =========================================================================

SELECT
    truck_brand_name,
    review,
    AI_SENTIMENT(review):categories[0]:sentiment::STRING AS overall_sentiment,
    AI_SENTIMENT(review, ['food quality', 'price', 'service', 'wait time']) AS by_topic
FROM tb_101.analytics.truck_reviews_v
LIMIT 15;


-- =========================================================================
-- 6.3  Translate into Norwegian
-- =========================================================================

SELECT
    language,
    review,
    AI_TRANSLATE(review, '', 'no') AS review_norwegian      -- '' = auto-detect source language
FROM tb_101.analytics.truck_reviews_v
WHERE language <> 'en'
LIMIT 10;

-- If the WHERE filter returns nothing, check the language values from 6.1 and adjust.


-- =========================================================================
-- 6.4  Classify every review into a business category
-- =========================================================================

SELECT
    review,
    AI_CLASSIFY(review, ['Food quality', 'Service', 'Price', 'Wait time', 'Cleanliness']):labels[0]::STRING AS category
FROM tb_101.analytics.truck_reviews_v
LIMIT 20;


-- =========================================================================
-- 6.5  Summarise many rows into one insight per brand
-- =========================================================================

WITH sample AS (
    SELECT truck_brand_name, review
    FROM tb_101.analytics.truck_reviews_v
    WHERE review IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY truck_brand_name ORDER BY review_id) <= 30
)
SELECT truck_brand_name, AI_SUMMARIZE_AGG(review) AS what_customers_say
FROM sample
GROUP BY truck_brand_name;


-- =========================================================================
-- 6.6  Free-form LLM call
-- =========================================================================

SELECT AI_COMPLETE(
    'claude-sonnet-4-6',
    'You are a food-truck operations advisor. Based on these customer reviews, give 3 concrete improvement actions: '
    || (SELECT LISTAGG(review, ' | ') FROM (
            SELECT review FROM tb_101.analytics.truck_reviews_v
            WHERE truck_brand_name = 'Freezing Point' LIMIT 25))
) AS advice;

-- If you get a model error, run:
SHOW CORTEX BASE MODELS;
-- and pick another model from the list (for example llama3.3-70b).


-- =========================================================================
-- 6.7  Cortex Code: describe it, and let the AI write it
-- =========================================================================
-- Open Cortex Code in Snowsight (AI assistant icon in the lower-right corner).
-- Try these prompts one by one:
--
-- 1. "Look at the TB_101 database and explain the data model to me: which tables
--     exist, how they join, and what business questions they can answer."
--
-- 2. "Write a query showing the top 5 menu items by revenue in each country
--     for 2022, and chart the result."
--
-- 3. "Create a dynamic table in NETCO_LAB.BRONZE that keeps daily revenue per
--     truck brand and country up to date, refreshing every hour."
--
-- 4. "Which columns in TB_101 contain personal data, and which of them are not
--     yet protected by a masking policy?"


-- =========================================================================
-- Clean up (after the session)
-- =========================================================================

USE ROLE ACCOUNTADMIN;
DROP DATABASE IF EXISTS tb_101_dev;
ALTER WAREHOUSE netco_wh SUSPEND;
ALTER WAREHOUSE tb_lab_wh SUSPEND;
-- Keep TB_101 and NETCO_LAB to keep practising - trials include free credits.
