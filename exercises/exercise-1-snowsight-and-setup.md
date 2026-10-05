# Exercise 1 — Snowsight Tour & Loading the Lab Data

**Time:** ~12 min  |  **Goal:** find your way around Snowsight and start the data load

[← Back to Lab Guide](../README.md)  |  [Next: Exercise 2 →](exercise-2-databases-and-loading.md)

---

## 1.1 Log in and check your account (2 min)

1. Log in to your Snowflake trial account (URL from your trial welcome email).
2. Bottom-left corner: click your name and check that your **role is ACCOUNTADMIN**.
3. Note your **edition** and **region**: click your name → **Account** → hover over the account. Trial accounts are Enterprise edition by default; the governance exercise needs Enterprise or higher.

> **Tip:** On a trial, your user owns the whole account. In a real customer account you rarely work as ACCOUNTADMIN; we come back to roles in Exercise 5.

## 1.2 Quick tour (3 min)

Follow along as the presenter shows these areas in the left navigation:

| Area | What it is for |
|------|----------------|
| **Projects → Workspaces** | Where you write SQL and Python. Files, folders, Git integration |
| **Catalog → Database Explorer** | Browse databases, schemas, tables, views and their lineage |
| **AI & ML** | Cortex AI features: Playground, Agents, Search, Snowflake Intelligence |
| **Monitoring → Query History** | Every query that ran, who ran it, how long it took, Query Profile |
| **Admin → Warehouses / Cost Management** | Compute and spend |
| **Data Products → Marketplace** | Third-party and public data you can query instantly |

## 1.3 Run the setup script (start now, ~5 min to finish)

1. Go to **Projects → Workspaces**, then click **+ Add new → SQL File**.
2. Paste the full contents of [`lab/00_setup.sql`](../lab/00_setup.sql).
3. Run all statements: **Cmd/Ctrl + Shift + Enter** (or the dropdown next to Run → *Run All*).
4. **Leave it running** and move on to 1.4.

The script creates a `TB_101` database for **Tasty Bytes**, a fictional global food-truck company, and loads several hundred million order rows from a public S3 bucket.

## 1.4 While it loads: the architecture in one picture

Snowflake has three layers that **scale independently**:

```
 ┌──────────────────────────────────────────────────────────┐
 │  CLOUD SERVICES   security · metadata · optimizer ·      │
 │                   governance · transactions              │
 ├──────────────────────────────────────────────────────────┤
 │  COMPUTE          virtual warehouses (XS … 6XL)          │
 │                   start in ~1 sec, suspend automatically │
 │                   billed per second when running         │
 ├──────────────────────────────────────────────────────────┤
 │  STORAGE          compressed, columnar, encrypted        │
 │                   one copy, shared by all warehouses     │
 └──────────────────────────────────────────────────────────┘
```

**Why it matters in a tender:** many teams can use the same data at the same time without competing for resources. Each team gets its own warehouse, and cost can be attributed per team.

## 1.5 Check the load

When the script finishes, the last result should show row counts for nine tables (`order_detail` is the largest).

If you see an error:

| Error | Fix |
|-------|-----|
| `Insufficient privileges` | Bottom-left: switch your role to ACCOUNTADMIN and run again |
| `Warehouse ... suspended` | Run `USE WAREHOUSE tb_load_wh;` and re-run from the COPY statements |
| Still running after 10 min | Ask the presenter; you can continue with Exercise 2, which does not need the large tables |

---

**What you learned:** Snowsight navigation, storage/compute separation, bulk loading from cloud storage with `COPY INTO`.
