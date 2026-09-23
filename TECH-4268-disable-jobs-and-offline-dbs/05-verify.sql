-- =============================================================================
-- 05-verify.sql
-- EW1R-REP-01 — Post-change verification
-- Ticket: TECH-4268
-- Run AFTER 04-reenable-2fa-job.sql and after the first successful 06:00
-- DBA_VCC_MEMSQL_DAILY_CHECKS run.
-- All checks must pass before closing the ticket.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Check 1: Disabled jobs — expect 50 disabled
-- All non-retained jobs must show DISABLED.
-- -----------------------------------------------------------------------------
PRINT '=== CHECK 1: Disabled jobs ===';
SELECT
    name                                            AS job_name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state
FROM msdb.dbo.sysjobs
WHERE name IN (
    -- VCC AWS
    'DBA_VCC_AWS_15MIN_CHECKS','DBA_VCC_AWS_DAILY_CHECKS','DBA_VCC_AWS_WEEKLY_CHECKS',
    -- VCC Core
    'DBA_VCC_DAILY_CHECKS','DBA_VCC_HOURLY_CHECKS','DBA_VCC_WEEKLY_CHECKS',
    'DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED',
    -- VCC Audit Collection
    'DBA_VCC_AUDIT_BACKUP_INFO_DETAILED','DBA_VCC_AUDIT_DATABASE_CREATION',
    'DBA_VCC_AUDIT_DATABASE_INFO_DETAILED','DBA_VCC_AUDIT_DATABASE_USERS_DETAILED',
    'DBA_VCC_AUDIT_DBINFO_DETAILED','DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED',
    'DBA_VCC_AUDIT_FAILED_LOGIN_SQL_CHECK','DBA_VCC_AUDIT_JOB_INFO_DETAILED',
    'DBA_VCC_AUDIT_LOGIN_SQL_CHECK','DBA_VCC_AUDIT_LOW_RUNNING_DRIVES_FILES_DETAILED',
    'DBA_VCC_AUDIT_SERVER_RESTART_REQUIRED_DETAILED','DBA_VCC_AUDIT_SQL_DATABASE_USAGE_DETAILED',
    'DBA_VCC_AUDIT_SQL_LOGINS_INFO_DETAILED','DBA_VCC_AUDIT_SQL_SERVER_DEFAULT_LOCATIONS_DETAILED',
    'DBA_VCC_AUDIT_TOP5_TABLES_PER_DATABASE_DETAILED','DBA_VCC_AUDIT_TRACE_FLAGS_DETAILED',
    -- VCC Server Monitoring
    'DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK','DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT',
    'DBA_VCC_MON_CONNECTION_CHECK','DBA_VCC_MON_Eventlog_CHECK',
    'DBA_VCC_MON_LOCAL_DRIVE_CHECK','DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK',
    'DBA_VCC_MON_SQL_SERVER_INFO_CHECK','DBA_VCC_MON_VLF_COUNT_CHECK',
    -- VCC MySQL / DXM
    'DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED','DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED',
    'DBA_VCC_MYSQL_DAILY_CHECKS','DBA_VCC_MYSQL_MON_PING_STATS',
    'DBA_VCC_MYSQL_MON_SQL_STATUS','DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK',
    'DBA_VCC_MYSQL_WEEKLY_CHECKS',
    -- VCC Cost / Atlassian
    'DBA_VCC_COST_Entity_Count_Collection','DBA_VCC_JIRA_MONTHEND_CHECKS',
    -- Baseline
    'BASELINE_CONNECTIONS','BASELINE_TABLE_SIZES',
    -- KAPP Schema
    'DBA - AUDIT - KAPP_Schema_details_Capture',
    -- DBA Maintenance
    'DBA - Maintenance - CHECKDB','DBA - Maintenance - History Cleanup',
    'DBA - Maintenance - ReIndex and Statistics - Local',
    'DBA - Maintenance - SQL Backups FULL','DBA - Maintenance - SQL Backups DIFF',
    'DBA - Maintenance - SQL Backups LOG',
    -- SSIS
    'DBA - SSISStatusCheck'
)
ORDER BY state, name;
-- Expected: all rows show DISABLED

-- -----------------------------------------------------------------------------
-- Check 2: Retained jobs — must still be ENABLED
-- -----------------------------------------------------------------------------
PRINT '=== CHECK 2: Retained jobs still enabled ===';
SELECT
    name                                            AS job_name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state
FROM msdb.dbo.sysjobs
WHERE name IN (
    'DBA_VCC_MEMSQL_DAILY_CHECKS',
    'DBA - Maintenance - SQL Backup EW1P-OCT',
    'syspolicy_purge_history'
)
ORDER BY name;
-- Expected: all 3 rows show ENABLED

-- -----------------------------------------------------------------------------
-- Check 3: Databases offline — expect 7 OFFLINE, DBA_VCC_MEMSQL ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== CHECK 3: Database states ===';
SELECT
    name                                            AS database_name,
    state_desc                                      AS current_state
FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb')
ORDER BY state_desc, name;
-- Expected OFFLINE: DBA_VCC_AWS, DBA_VCC_MYSQL, DBA_VCC_COST,
--                   DBA_VCC_ATLASSIAN, KURTOSYS_BASELINE, Utilities
-- Expected ONLINE:  DBA_VCC_MEMSQL, DBA_VCC, master, model, msdb, tempdb
-- DBA_VCC stays ONLINE — confirmed 2026-09-23 (connection proxy for 2FA alerts)

-- -----------------------------------------------------------------------------
-- Check 4: DBA_VCC_MEMSQL_DAILY_CHECKS — confirm successful run after re-enable
-- -----------------------------------------------------------------------------
PRINT '=== CHECK 4: DBA_VCC_MEMSQL_DAILY_CHECKS last run outcome ===';
SELECT TOP 3
    j.name,
    h.run_date,
    h.run_time,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'In Progress'
    END                                             AS outcome,
    h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
WHERE j.name = 'DBA_VCC_MEMSQL_DAILY_CHECKS'
  AND h.step_id = 0
ORDER BY h.run_date DESC, h.run_time DESC;
-- Expected: most recent row shows Succeeded with run_date = today

-- -----------------------------------------------------------------------------
-- Check 5: DBA_VCC_MEMSQL data freshness — confirm data is flowing post re-enable
-- Compare against baseline from 00-pre-change-state-capture.sql Section 5.
-- -----------------------------------------------------------------------------
PRINT '=== CHECK 5: DBA_VCC_MEMSQL data freshness ===';
SELECT 'INFO_ClientSizes_Sizes_FP'     AS table_name, MAX(DateChecked) AS last_data, COUNT(*) AS row_count FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'INFO_Client_FP_Detail',         MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_Client_FP_Detail
UNION ALL
SELECT 'INFO_KAPP_Workflow_Run_Detail',  MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_KAPP_Workflow_Run_Detail
UNION ALL
SELECT 'BAS_Ping_Stat',                 MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
UNION ALL
SELECT 'BAS_SQL_Status',                MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status;
-- Expected: MAX(DateChecked) updated to today for BAS_Ping_Stat and BAS_SQL_Status
-- after the first successful 06:00 run.

-- -----------------------------------------------------------------------------
-- Check 6: Grafana 2FA alert rules — confirm evaluating without error
-- This must be verified manually in the Grafana UI.
-- Navigate to: Alerting > Alert rules
-- Confirm both rules show state = Normal or Pending (not Error or NoData).
-- -----------------------------------------------------------------------------
PRINT '=== CHECK 6: MANUAL — Verify in Grafana UI ===';
PRINT '>>> Navigate to Alerting > Alert rules in Grafana (https://ew1r-rep-01)';
PRINT '>>> Confirm: KAPP Client Config Alert — state is Normal or Pending (not Error)';
PRINT '>>> Confirm: KAPP Client Application Auth Config Alert — state is Normal or Pending (not Error)';
PRINT '>>> If either shows Error state, check the datasource connection and SP execution.';

-- -----------------------------------------------------------------------------
-- Check 7: No unexpected job failures since the change
-- Review any jobs that ran and failed after the disable window.
-- Only DBA - Maintenance - SQL Backup EW1P-OCT and syspolicy_purge_history
-- should have run. DBA_VCC_MEMSQL_DAILY_CHECKS should show Succeeded.
-- -----------------------------------------------------------------------------
PRINT '=== CHECK 7: Job runs since change ===';
SELECT
    j.name,
    h.run_date,
    h.run_time,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'In Progress'
    END                                             AS outcome
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
WHERE h.step_id = 0
  AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(DAY, -1, GETDATE())
ORDER BY h.run_date DESC, h.run_time DESC;
