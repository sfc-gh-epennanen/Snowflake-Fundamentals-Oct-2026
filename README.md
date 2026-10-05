# Snowflake Fundamentals — Hands-on Lab for Netcompany Norway

**Date:** Tuesday 6 October 2026, 16:00–18:00 (dinner at 18:00)  |  **Presenter:** Elli Pennanen, Senior Partner Solution Engineer, Snowflake

Welcome! In this session you get hands-on with Snowflake's core capabilities in your own trial account. After that, we look at how to position Snowflake in pre-sales and tenders.

## Agenda

| Time | Block |
|------|-------|
| 16:00 – 17:25 | **Hands-on Snowflake Fundamentals** (this guide) |
| 17:25 – 17:30 | Break |
| 17:30 – 18:00 | **Snowflake in a Sales Context**: business value, tender answers, Q&A ([playbook](sales/sales-context-playbook.md)) |
| 18:00 | Dinner |

## Before you arrive

- [ ] You have a **Snowflake trial account** (30 days, free credits). Choose **Enterprise** edition and an **EU region** (e.g. AWS EU Stockholm or Frankfurt, or Azure North/West Europe).
- [ ] You can **log in** and see Snowsight in your browser (Chrome, Edge or Firefox).
- [ ] You have this lab guide open in a second window or screen.

## The scenario: Tasty Bytes

All exercises use **Tasty Bytes**, Snowflake's fictional global food-truck company: truck brands in cities around the world, hundreds of millions of order lines, a customer loyalty programme (with personal data), and customer reviews in several languages.

## Lab structure

| # | Exercise | You will learn | Time |
|---|----------|----------------|------|
| 1 | [Snowsight tour & loading the lab data](exercises/exercise-1-snowsight-and-setup.md) | Navigation, architecture, bulk load | 12 min |
| 2 | [Databases, schemas, tables & first queries](exercises/exercise-2-databases-and-loading.md) | Object hierarchy, stages, COPY INTO, Snowflake SQL | 15 min |
| 3 | [Virtual warehouses, caching & cost control](exercises/exercise-3-warehouses-and-performance.md) | Elastic compute, Query Profile, resource monitors | 12 min |
| 4 | [Time Travel, zero-copy cloning & JSON](exercises/exercise-4-time-travel-clone-json.md) | Clone, Time Travel, UNDROP, VARIANT | 15 min |
| 5 | [Roles & data protection](exercises/exercise-5-governance.md) | RBAC, masking policies, classification | 10 min |
| 6 | [AI inside the platform](exercises/exercise-6-cortex-ai.md) | Cortex AI SQL functions, Cortex Code | 18 min |

**Setup script:** [`lab/00_setup.sql`](lab/00_setup.sql). You run it at the start of Exercise 1.

## How this lab works

- Every step has a SQL block: **copy → paste into a Workspace → run** (Cmd/Ctrl + Enter runs the statement under the cursor).
- Use one SQL file per exercise, so you can go back.
- Fall behind? Skip ahead. Each exercise only depends on the setup script and the `NETCO_LAB` database from Exercise 2.
- Trial credits are free, but **scale warehouses back down** when an exercise tells you to.

## Key concepts, one line each

| Concept | In one line |
|---------|-------------|
| **Virtual warehouse** | A compute cluster you start, stop and resize in seconds. Billed per second while running. |
| **Database / Schema** | Logical containers for tables, views, stages, functions. |
| **Stage** | A pointer to files, internal or in S3/Azure/GCS, used to load and unload data. |
| **VARIANT** | A column type that holds JSON/semi-structured data and is queryable with SQL. |
| **Time Travel** | Query or restore data as it was at a point in the past. |
| **Zero-copy clone** | An instant copy of a table, schema or database that shares the same storage. |
| **Masking policy** | A column-level rule that shows or hides data based on the user's role. |
| **Cortex AI** | LLM functions callable from SQL, running inside Snowflake's security boundary. |
| **Cortex Code** | Snowflake's AI coding assistant, built into Snowsight. |

## After the session

- Your trial stays active for 30 days. Keep experimenting.
- Free learning: Snowflake Quickstarts (search "Zero to Snowflake"), Snowflake University, SnowPro Core certification.
- Questions about a tender or customer opportunity: contact Elli Pennanen (elli.pennanen@snowflake.com).
