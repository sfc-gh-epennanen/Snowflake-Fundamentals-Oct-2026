/*****************************************************************************************
  Exercise 1 — Snowsight Tour & Loading the Lab Data
  ~12 min  |  Find your way around Snowsight and start the data load

  NOTE: The actual data load is in 00_setup.sql.
  This file covers the checks and orientation steps.
*****************************************************************************************/

-- =========================================================================
-- 1.1  Log in and check your account
-- =========================================================================
-- 1. Log in to your Snowflake trial account (URL from your trial welcome email).
-- 2. Bottom-left: click your name and check that your role is ACCOUNTADMIN.
-- 3. Note your edition and region: click your name → Account → hover over the account.


-- =========================================================================
-- 1.2  Quick tour (follow along with the presenter)
-- =========================================================================
-- Area                             | What it is for
-- ---------------------------------|-------------------------------------------
-- Projects → Workspaces            | Write SQL and Python; files, folders, Git
-- Catalog → Database Explorer      | Browse databases, schemas, tables, lineage
-- AI & ML                          | Cortex AI: Playground, Agents, Search
-- Monitoring → Query History       | Every query, who ran it, query profile
-- Admin → Warehouses / Cost Mgmt   | Compute and spend
-- Data Products → Marketplace      | Third-party and public data


-- =========================================================================
-- 1.3  Run the setup script
-- =========================================================================
-- Go to Projects → Workspaces → + → SQL File
-- Paste the full contents of lab/00_setup.sql
-- Run All: Cmd/Ctrl + Shift + Enter
-- Leave it running and continue to 1.4.


-- =========================================================================
-- 1.4  Architecture (presenter explains while data loads)
-- =========================================================================
-- Snowflake has three layers that scale independently:
--
--  ┌──────────────────────────────────────────────────────────┐
--  │  CLOUD SERVICES   security · metadata · optimizer        │
--  ├──────────────────────────────────────────────────────────┤
--  │  COMPUTE          virtual warehouses (XS … 6XL)          │
--  ├──────────────────────────────────────────────────────────┤
--  │  STORAGE          compressed, columnar, encrypted        │
--  └──────────────────────────────────────────────────────────┘


-- =========================================================================
-- 1.5  Check the load
-- =========================================================================
-- When 00_setup.sql finishes, the last result shows row counts.
-- If you see errors:
--   "Insufficient privileges" → switch role to ACCOUNTADMIN
--   "Warehouse ... suspended" → USE WAREHOUSE tb_load_wh; and re-run COPY statements
