-- =============================================================================
-- 03-databases-offline.sql
-- EW1R-REP-01 — Take non-2FA databases offline
-- Ticket: TECH-4268
-- Parent epic: TECH-3410
-- Executed: 2026-09-27
-- Executed by: Lunga Ndzimande
-- =============================================================================
--
-- PURPOSE
-- -------
-- Reduce EW1R-REP-01 to the minimum footprint required to keep the two Grafana
-- 2FA alert rules evaluating. Everything else is taken offline and left off
-- so the server is ready for decommission.
--
-- Nothing is dropped or deleted. SET OFFLINE is fully reversible at any time
-- using 06-rollback.sql — uncomment the relevant ALTER DATABASE SET ONLINE line
-- and the database comes straight back up.
--
-- DATABASES TAKEN OFFLINE (6)
-- ---------------------------
--   DBA_VCC_AWS        — KAPP API and AWS monitoring data
--   DBA_VCC_MYSQL      — MySQL / DXM monitoring data
--   DBA_VCC_COST       — Client billing and entity count data
--   DBA_VCC_ATLASSIAN  — Jira reference data
--   KURTOSYS_BASELINE  — SQL Server performance baselines
--   Utilities          — DBA tooling, Ola Hallengren, Zabbix procs
--
-- DATABASES THAT STAY ONLINE (2)
-- --------------------------------
--   DBA_VCC        — Grafana 2FA connection proxy (confirmed 2026-09-23)
--   DBA_VCC_MEMSQL — 2FA job writes here; Grafana alert queries read from here
--
-- PRE-CHECKS COMPLETED BEFORE THIS SCRIPT WAS RUN
-- -------------------------------------------------
--   1. Grafana 2FA datasource dependency confirmed — DBA_VCC stays ONLINE
--   2. Final FULL backups taken for all 8 databases and synced to S3
--   3. All 50 non-retained SQL Agent jobs disabled (02-disable-jobs.sql)
--   4. DBA Team notified — ~70 Grafana dashboards will stop returning data
--   5. Monitoring team notified — Zabbix Zab_* checks stop when Utilities goes offline
--
-- =============================================================================


-- -----------------------------------------------------------------------------
-- PRE-CHECK: Confirm no active connections to databases being taken offline.
-- Review output before proceeding — kill any blocking sessions if needed.
-- WITH ROLLBACK IMMEDIATE will kill active transactions but it is safer to
-- confirm no connections exist first to avoid unexpected rollbacks.
-- -----------------------------------------------------------------------------
SELECT
    db.name                                         AS database_name,
    COUNT(sp.spid)                                  AS active_connections
FROM sys.databases db
LEFT JOIN sys.sysprocesses sp ON db.database_id = sp.dbid AND sp.spid > 50
WHERE db.name IN (
    'DBA_VCC_AWS','DBA_VCC_MYSQL',
    'DBA_VCC_COST','DBA_VCC_ATLASSIAN','KURTOSYS_BASELINE','Utilities'
)
GROUP BY db.name
ORDER BY db.name;


-- =============================================================================
-- STEP 1: DBA_VCC_AWS — OFFLINE
-- =============================================================================
--
-- What this database contains:
--   Collection of AWS infrastructure monitoring data and KAPP API query
--   tracking data. The largest database on the server at ~182 GB, driven
--   primarily by the DBA_VCC_AWS_* job group which collected AWS cost,
--   resource, and API metrics at 15-minute, daily, and weekly intervals.
--   Also holds Encore and BNY IIS CloudWatch ingestion data.
--
-- Why it is being taken offline:
--   All 3 DBA_VCC_AWS_* collection jobs have been disabled in step 02.
--   No active consumer has been confirmed for this data. The database has
--   been growing continuously (563M+ rows in key tables) with no downstream
--   use case that requires it to stay online during the observation period.
--   Taking it offline stops all further growth and reduces server I/O.
--
-- What stops when this goes offline:
--   - DBA_VCC_AWS_15MIN_CHECKS stops writing (already disabled)
--   - DBA_VCC_AWS_DAILY_CHECKS stops writing (already disabled)
--   - DBA_VCC_AWS_WEEKLY_CHECKS stops writing (already disabled)
--   - Encore / BNY IIS CloudWatch ingestion stops
--   - KAPP API query tracking frozen at last collection date
--   - AWS cost data frozen — no new entries
--
-- Impact accepted: No active consumer confirmed. Data is frozen, not lost.
-- Rollback: ALTER DATABASE DBA_VCC_AWS SET ONLINE; in 06-rollback.sql
--
-- =============================================================================
ALTER DATABASE DBA_VCC_AWS SET OFFLINE WITH ROLLBACK IMMEDIATE;


-- =============================================================================
-- STEP 2: DBA_VCC_MYSQL — OFFLINE
-- =============================================================================
--
-- What this database contains:
--   MySQL and DXM (Data Exchange Manager) monitoring data collected from
--   linked server connections to MySQL instances across EC1P, EW1R, EW2P,
--   and UE1P environments. Holds DXM client size tracking, WPv2 monitoring
--   data, and MySQL server health metrics at daily and weekly intervals.
--   Database size ~25 GB.
--
-- Why it is being taken offline:
--   All 7 DBA_VCC_MYSQL_* collection jobs have been disabled in step 02.
--   Two of these jobs (WPv2-related) were failing daily — taking this
--   database offline stops those daily failures as a side effect.
--   No active consumer has been confirmed for this data during the
--   observation period.
--
-- What stops when this goes offline:
--   - All DBA_VCC_MYSQL_* jobs stop writing (already disabled)
--   - DXM client size tracking stops across all environments
--   - MySQL server health monitoring stops
--   - 2 daily-failing WPv2 jobs stop failing (positive side effect)
--
-- Impact accepted: No active consumer confirmed. Daily job failures stop.
-- Rollback: ALTER DATABASE DBA_VCC_MYSQL SET ONLINE; in 06-rollback.sql
--
-- =============================================================================
ALTER DATABASE DBA_VCC_MYSQL SET OFFLINE WITH ROLLBACK IMMEDIATE;


-- =============================================================================
-- STEP 3: DBA_VCC — *** STAYS ONLINE *** ✅ CONFIRMED 2026-09-23
-- =============================================================================
--
-- Why DBA_VCC must NOT be taken offline:
--   Both Grafana 2FA alert rules (KAPP Client Config Alert and KAPP Client
--   Application Auth Config Alert) use datasource UID e8597015-eb43-4adc-8da4-
--   090eed43ee62, which is the "DBA_VCC" mssql datasource configured in Grafana
--   to connect to DBA_VCC on localhost (EW1R-REP-01).
--
--   The panel queries use 3-part names to reach DBA_VCC_MEMSQL directly:
--     FROM DBA_VCC_MEMSQL..INFO_Client_FP_Detail
--     FROM [DBA_VCC_MEMSQL].[dbo].[INFO_Client_Application_Auth_Config_Detail]
--     EXEC [DBA_VCC_MEMSQL]..[REP_CLIENT_APP_AUTH_CONFIG_CHANGES_DETAILED_REPORT]
--
--   DBA_VCC is the connection entry point. SQL Server authenticates the Grafana
--   connection against DBA_VCC first. If DBA_VCC is offline, SQL Server rejects
--   the connection before the query ever reaches DBA_VCC_MEMSQL — both 2FA
--   alerts immediately enter Error state and stop evaluating.
--
--   DBA_VCC must remain ONLINE for the entire observation period. It will only
--   be taken offline as part of the final decommission of EW1R-REP-01, after
--   the 2FA alerting chain has been migrated to another server.
--
-- =============================================================================
PRINT '>>> DBA_VCC stays ONLINE — confirmed 2026-09-23.';
PRINT '>>> It is the Grafana connection entry point for both 2FA alert rules.';
PRINT '>>> Taking it offline breaks both alerts immediately. Do not change this.';


-- =============================================================================
-- STEP 4: DBA_VCC_COST — OFFLINE
-- =============================================================================
--
-- What this database contains:
--   Client entity count and billing data collected by the
--   DBA_VCC_COST_Entity_Count_Collection job. Holds historical client
--   utilisation and growth data used by the KAPP Client Utilisation and
--   Growth Report in Grafana. Database size ~5 GB. Recovery model: FULL
--   (holds client billing data — retained per policy).
--
-- Why it is being taken offline:
--   The DBA_VCC_COST_Entity_Count_Collection job has been disabled in step 02.
--   The database has been stale since 4 May 2026 — no new data has been
--   collected for over 4 months. Taking it offline has no additional impact
--   on data freshness beyond what already exists.
--   A FULL backup was taken before this step and retained in S3 per policy
--   due to the client billing data it contains.
--
-- What stops when this goes offline:
--   - DBA_VCC_COST_Entity_Count_Collection stops writing (already disabled)
--   - KAPP Client Utilisation and Growth Report in Grafana stops returning data
--   - No other confirmed active consumer
--
-- Impact accepted: Already stale since 4 May 2026. Backup retained per policy.
-- Rollback: ALTER DATABASE DBA_VCC_COST SET ONLINE; in 06-rollback.sql
--
-- =============================================================================
ALTER DATABASE DBA_VCC_COST SET OFFLINE WITH ROLLBACK IMMEDIATE;


-- =============================================================================
-- STEP 5: DBA_VCC_ATLASSIAN — OFFLINE
-- =============================================================================
--
-- What this database contains:
--   Jira reference data collected by the DBA_VCC_JIRA_MONTHEND_CHECKS job.
--   Holds Jira sprint and month-end reporting data pulled from the Atlassian
--   API. Database size ~2 GB.
--
-- Why it is being taken offline:
--   The DBA_VCC_JIRA_MONTHEND_CHECKS job has been disabled in step 02.
--   No active consumer or downstream dependency has been confirmed for this
--   database. It has no role in the 2FA alerting chain or any retained
--   Grafana dashboard that remains functional after this change.
--
-- What stops when this goes offline:
--   - DBA_VCC_JIRA_MONTHEND_CHECKS stops writing (already disabled)
--   - Jira sprint pull data frozen
--   - No other confirmed active consumer
--
-- Impact accepted: No active consumer confirmed. No operational impact.
-- Rollback: ALTER DATABASE DBA_VCC_ATLASSIAN SET ONLINE; in 06-rollback.sql
--
-- =============================================================================
ALTER DATABASE DBA_VCC_ATLASSIAN SET OFFLINE WITH ROLLBACK IMMEDIATE;


-- =============================================================================
-- STEP 6: KURTOSYS_BASELINE — OFFLINE
-- =============================================================================
--
-- What this database contains:
--   SQL Server performance baseline data collected by the BASELINE_CONNECTIONS
--   and BASELINE_TABLE_SIZES jobs. Holds historical connection counts and
--   table size snapshots used for capacity planning and trend analysis.
--   Database size ~50 GB.
--
-- Why it is being taken offline:
--   Both BASELINE_* collection jobs have been disabled in step 02.
--   No active consumer or Grafana dashboard dependency has been confirmed
--   for this database. Baseline data has no role in the 2FA alerting chain.
--   Taking it offline stops further growth and reduces server I/O.
--
-- What stops when this goes offline:
--   - BASELINE_CONNECTIONS stops writing (already disabled)
--   - BASELINE_TABLE_SIZES stops writing (already disabled)
--   - Historical baseline trend data frozen
--   - No other confirmed active consumer
--
-- Impact accepted: No active consumer confirmed. No operational impact.
-- Rollback: ALTER DATABASE KURTOSYS_BASELINE SET ONLINE; in 06-rollback.sql
--
-- =============================================================================
ALTER DATABASE KURTOSYS_BASELINE SET OFFLINE WITH ROLLBACK IMMEDIATE;


-- =============================================================================
-- STEP 7: Utilities — OFFLINE  ⚠️ RUN LAST
-- =============================================================================
--
-- What this database contains:
--   The DBA tooling database. Hosts:
--     - Ola Hallengren maintenance solution (DatabaseBackup, DatabaseIntegrityCheck,
--       IndexOptimize stored procedures used by all DBA Maintenance jobs)
--     - USP_DatabaseBackupMoveToS3 — S3 sync procedure used by backup jobs
--     - Zabbix integration procedures (USP_ZAB_*) — read by Zabbix via linked
--       server for deadlock monitoring, sync checks, and AG lag checks
--     - Various DBA utility procedures and logging tables
--   Database size ~0.18 GB.
--
-- Why it is being taken offline:
--   All DBA Maintenance jobs that depend on Utilities (CHECKDB, History Cleanup,
--   ReIndex and Statistics, SQL Backups FULL/DIFF/LOG) have been disabled in
--   step 02. With those jobs disabled, the Ola Hallengren procedures in Utilities
--   are no longer called. The only retained backup job (DBA - Maintenance - SQL
--   Backup EW1P-OCT) uses a different mechanism and does not depend on Utilities.
--   Taking Utilities offline is safe once all dependent jobs are confirmed disabled.
--
-- Why this is run LAST:
--   Utilities hosts the Ola Hallengren DatabaseBackup procedure used in
--   01-final-backups.sql. It must remain online until all final backups are
--   complete. It is taken offline last to ensure no dependency is broken
--   during the execution sequence.
--
-- What stops when this goes offline:
--   - All Ola Hallengren maintenance procedures become unavailable
--     (all dependent jobs already disabled in step 02 — no operational impact)
--   - USP_DatabaseBackupMoveToS3 becomes unavailable
--     (backup jobs already disabled — no operational impact)
--   - Zabbix USP_ZAB_* procedure reads stop — Zabbix deadlock, sync check,
--     and AG lag checks sourced from this server stop firing
--     (monitoring team notified before this step)
--
-- ⚠️ MONITORING TEAM MUST BE NOTIFIED BEFORE THIS STEP:
--   Zabbix reads Utilities.dbo.Zab_* tables via linked server from the
--   Zabbix server. Those checks stop the moment Utilities goes offline.
--   Confirm the monitoring team has acknowledged this before proceeding.
--
-- Impact accepted: All dependent jobs disabled. Monitoring team notified.
-- Rollback: ALTER DATABASE Utilities SET ONLINE; in 06-rollback.sql
--   Note: After bringing Utilities back online, re-enable any maintenance
--   jobs that need to run before the next scheduled window.
--
-- =============================================================================
ALTER DATABASE Utilities SET OFFLINE WITH ROLLBACK IMMEDIATE;


-- =============================================================================
-- CONFIRMATION QUERY — run after all steps above complete
-- =============================================================================
--
-- Expected results:
--   OFFLINE : DBA_VCC_AWS, DBA_VCC_ATLASSIAN, DBA_VCC_COST,
--             DBA_VCC_MYSQL, KURTOSYS_BASELINE, Utilities
--   ONLINE  : DBA_VCC, DBA_VCC_MEMSQL
--
-- If any database shows an unexpected state, do not proceed to step 04.
-- Investigate and resolve before continuing.
--
-- =============================================================================
SELECT
    name                                            AS database_name,
    state_desc                                      AS current_state,
    recovery_model_desc                             AS recovery_model
FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb')
ORDER BY state_desc, name;
