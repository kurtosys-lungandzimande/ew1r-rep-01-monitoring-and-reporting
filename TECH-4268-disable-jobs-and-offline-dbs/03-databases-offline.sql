-- =============================================================================
-- 03-databases-offline.sql
-- EW1R-REP-01 — Take non-2FA databases offline
-- Ticket: TECH-4268
-- Run AFTER 02-disable-jobs.sql.
-- PRE-CHECK: Confirm 2FA alert datasource dependency (see README.md step 3)
-- before taking DBA_VCC offline.
-- Nothing is dropped. SET OFFLINE is fully reversible via 06-rollback.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PRE-CHECK: Confirm no active connections to databases being taken offline.
-- Review output before proceeding — kill any blocking sessions if needed.
-- -----------------------------------------------------------------------------
SELECT
    db.name                                         AS database_name,
    COUNT(sp.spid)                                  AS active_connections
FROM sys.databases db
LEFT JOIN sys.sysprocesses sp ON db.database_id = sp.dbid
WHERE db.name IN (
    'DBA_VCC_AWS','DBA_VCC_MYSQL','DBA_VCC',
    'DBA_VCC_COST','DBA_VCC_ATLASSIAN','KURTOSYS_BASELINE','Utilities'
)
GROUP BY db.name
ORDER BY db.name;

-- -----------------------------------------------------------------------------
-- Step 1: DBA_VCC_AWS (182 GB — KAPP API and AWS monitoring)
-- Consequence: DBA_VCC_AWS_15MIN_CHECKS, DAILY, WEEKLY stop writing.
--              KAPP API query tracking frozen. AWS cost data frozen.
-- -----------------------------------------------------------------------------
ALTER DATABASE DBA_VCC_AWS SET OFFLINE WITH ROLLBACK IMMEDIATE;

-- -----------------------------------------------------------------------------
-- Step 2: DBA_VCC_MYSQL (25 GB — MySQL/DXM monitoring)
-- Consequence: All DBA_VCC_MYSQL_* jobs stop writing.
--              DXM client size tracking stops. 2 daily-failing WPv2 jobs stop failing.
-- -----------------------------------------------------------------------------
ALTER DATABASE DBA_VCC_MYSQL SET OFFLINE WITH ROLLBACK IMMEDIATE;

-- -----------------------------------------------------------------------------
-- Step 3: DBA_VCC — STAYS ONLINE ✅ CONFIRMED 2026-09-23
-- Pre-check 1 CLOSED.
--
-- Both 2FA Grafana alert rules use datasource UID e8597015 which connects to
-- DBA_VCC on localhost. The panel queries use 3-part names to reach
-- DBA_VCC_MEMSQL directly:
--   FROM DBA_VCC_MEMSQL..INFO_Client_FP_Detail
--   FROM [DBA_VCC_MEMSQL].[dbo].[INFO_Client_Application_Auth_Config_Detail]
--   EXEC [DBA_VCC_MEMSQL]..[REP_CLIENT_APP_AUTH_CONFIG_CHANGES_DETAILED_REPORT]
--
-- DBA_VCC is the connection entry point. If it goes offline, SQL Server
-- rejects the Grafana connection before the query reaches DBA_VCC_MEMSQL.
-- Both 2FA alerts break immediately.
--
-- DBA_VCC must remain ONLINE for the duration of the observation period.
-- It will be taken offline only as part of the final decommission.
-- -----------------------------------------------------------------------------
PRINT '>>> DBA_VCC stays ONLINE — confirmed 2026-09-23. Connection proxy for both 2FA alert queries.';

-- -----------------------------------------------------------------------------
-- Step 4: DBA_VCC_COST (5 GB — client billing data, FULL recovery)
-- Consequence: DBA_VCC_COST_Entity_Count_Collection stops writing.
--              KAPP Client Utilisation and Growth Report stops returning data.
--              Already stale since 4 May 2026 — no new impact on data freshness.
-- -----------------------------------------------------------------------------
ALTER DATABASE DBA_VCC_COST SET OFFLINE WITH ROLLBACK IMMEDIATE;

-- -----------------------------------------------------------------------------
-- Step 5: DBA_VCC_ATLASSIAN (2 GB — Jira reference data)
-- Consequence: No active writer or confirmed consumer — no operational impact.
-- -----------------------------------------------------------------------------
ALTER DATABASE DBA_VCC_ATLASSIAN SET OFFLINE WITH ROLLBACK IMMEDIATE;

-- -----------------------------------------------------------------------------
-- Step 6: KURTOSYS_BASELINE (50 GB — performance baselines)
-- Consequence: BASELINE_CONNECTIONS and BASELINE_TABLE_SIZES stop writing.
--              No confirmed active consumer.
-- -----------------------------------------------------------------------------
ALTER DATABASE KURTOSYS_BASELINE SET OFFLINE WITH ROLLBACK IMMEDIATE;

-- -----------------------------------------------------------------------------
-- Step 7: Utilities (0.18 GB — DBA tooling, Ola Hallengren, Zabbix procs)
-- ⚠️ Run LAST — Utilities hosts the Ola Hallengren maintenance procedures
--    and the Zabbix integration procs (USP_ZAB_*).
--    Monitoring team must be notified before this step — Zabbix reads
--    Utilities.dbo.Zab_* tables via linked server for deadlock, sync check,
--    and AG lag. Those checks stop when Utilities goes offline.
-- Consequence: All Ola Hallengren maintenance jobs stop working (already
--              disabled in step 02). Zabbix Zab_* table reads stop.
-- -----------------------------------------------------------------------------
ALTER DATABASE Utilities SET OFFLINE WITH ROLLBACK IMMEDIATE;

-- -----------------------------------------------------------------------------
-- Confirm: all targeted databases are now OFFLINE, retained databases ONLINE
-- Expected OFFLINE: DBA_VCC_AWS, DBA_VCC_MYSQL, DBA_VCC_COST,
--                   DBA_VCC_ATLASSIAN, KURTOSYS_BASELINE, Utilities
-- Expected ONLINE:  DBA_VCC_MEMSQL, DBA_VCC, master, model, msdb, tempdb
-- DBA_VCC stays ONLINE — confirmed 2026-09-23 (connection proxy for 2FA alerts)
-- -----------------------------------------------------------------------------
SELECT
    name                                            AS database_name,
    state_desc                                      AS current_state,
    recovery_model_desc                             AS recovery_model
FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb')
ORDER BY state_desc, name;
