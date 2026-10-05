# Exercise 3 — Virtual Warehouses, Caching & Cost Control

**Time:** ~12 min  |  **Goal:** see elastic compute and per-second billing for yourself

[← Exercise 2](exercise-2-databases-and-loading.md)  |  [Next: Exercise 4 →](exercise-4-time-travel-clone-json.md)

---

## 3.1 Run a heavy query on the smallest warehouse

Turn the result cache off first, so we measure real compute:

```sql
USE ROLE SYSADMIN;
USE WAREHOUSE netco_wh;                 -- XSMALL
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

SELECT
    primary_city,
    menu_type,
    COUNT(*)                 AS order_lines,
    ROUND(SUM(price))        AS revenue_usd
FROM tb_101.analytics.orders_v
WHERE YEAR(date) = 2022
GROUP BY ALL
ORDER BY revenue_usd DESC
LIMIT 25;
```

Note the duration shown under the results.

## 3.2 Scale up instantly, with no data movement

```sql
ALTER WAREHOUSE netco_wh SET WAREHOUSE_SIZE = 'LARGE';
-- re-run the same query from 3.1
```

Each size step **doubles** compute and **doubles** the per-second cost. When a query parallelises well, it finishes about twice as fast at about the same total cost.

**Scale back down straight away** (trial credits!):

```sql
ALTER WAREHOUSE netco_wh SET WAREHOUSE_SIZE = 'XSMALL';
```

## 3.3 Result cache

```sql
ALTER SESSION SET USE_CACHED_RESULT = TRUE;
-- run the 3.1 query twice
```

The second run returns in milliseconds. It uses **no warehouse compute**, and the cache is shared across users with the same access.

## 3.4 Look inside a query: Query Profile

**Monitoring → Query History**, then click your LARGE query → **Query Profile**. Point out:
- **Partitions scanned vs total** (pruning, Snowflake's automatic "indexing")
- The most expensive operator
- Bytes spilled (a sign the warehouse is too small)

## 3.5 Cost guardrails (this is what CFOs ask about)

```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE RESOURCE MONITOR netco_lab_monitor
    WITH CREDIT_QUOTA = 10
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS ON 80 PERCENT DO NOTIFY
             ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE netco_wh SET RESOURCE_MONITOR = netco_lab_monitor;

SHOW WAREHOUSES;
```

Then look at **Admin → Cost Management**: spend per warehouse, budgets, and recommendations.

> **For tenders:** the cost model is consumption-based, per second, with auto-suspend. Spend can be capped with resource monitors and budgets, and attributed per warehouse, user or tag. Multi-cluster warehouses (Enterprise) add clusters automatically for concurrency peaks, such as month-end reporting.

---

**What you learned:** resizing, the cost/performance trade-off, result cache, Query Profile, resource monitors.
