-- =============================================================================
-- T06-rollback-verify.sql
-- TECH-4268 — Rollback verification test
-- Run AFTER executing any section of 06-rollback.sql.
-- Compare output against T01 baseline to confirm the rollback is complete.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TEST 1: Databases that were rolled back are now ONLINE
-- Edit the IN list to match only the databases you rolled back.
-- PASS: all rolled-back databases show ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 1: Rolled-back databases are ONLINE ===';
SELECT
    name                                                AS database_name,
    state_desc                                          AS current_state,
    CASE state_desc
        WHEN 'ONLINE' THEN 'PASS'
        ELSE 'FAIL — expected ONLINE after rollback'
    END                                                 AS result
FROM sys.databases
WHERE name IN (
    -- Uncomment only the databases you rolled back:
    'DBA_VCC_AWS',
    'DBA_VCC_MYSQL',
    -- 'DBA_VCC',           -- was never taken offline
    'DBA_VCC_COST',
    'DBA_VCC_ATLASSIAN',
    'KURTOSYS_BASELINE',
    'Utilities'
)
ORDER BY name;

-- -----------------------------------------------------------------------------
-- TEST 2: Jobs that were rolled back are now ENABLED
-- Edit the IN list to match only the jobs you re-enabled.
-- PASS: all rolled-back jobs show ENABLED
-- -----------------------------------------------------------------------------
PRINT '=== TEST 2: Rolled-back jobs are ENABLED ===';
SELECT
    name                                                AS job_name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    CASE enabled WHEN 1 THEN 'PASS' ELSE 'FAIL — expected ENABLED after rollback' END AS result
FROM msdb.dbo.sysjobs
WHERE name IN (
    -- Uncomment only the jobs you re-enabled:
    'DBA_VCC_AWS_15MIN_CHECKS','DBA_VCC_AWS_DAILY_CHECKS','DBA_VCC_AWS_WEEKLY_CHECKS',
    'DBA_VCC_DAILY_CHECKS','DBA_VCC_HOURLY_CHECKS','DBA_VCC_WEEKLY_CHECKS',
    'DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED',
    'DBA_VCC_AUDIT_BACKUP_INFO_DETAILED','DBA_VCC_AUDIT_DATABASE_CREATION',
    'DBA_VCC_AUDIT_DATABASE_INFO_DETAILED','DBA_VCC_AUDIT_DATABASE_USERS_DETAILED',
    'DBA_VCC_AUDIT_DBINFO_DETAILED','DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED',
    'DBA_VCC_AUDIT_FAILED_LOGIN_SQL_CHECK','DBA_VCC_AUDIT_JOB_INFO_DETAILED',
    'DBA_VCC_AUDIT_LOGIN_SQL_CHECK','DBA_VCC_AUDIT_LOW_RUNNING_DRIVES_FILES_DETAILED',
    'DBA_VCC_AUDIT_SERVER_RESTART_REQUIRED_DETAILED','DBA_VCC_AUDIT_SQL_DATABASE_USAGE_DETAILED',
    'DBA_VCC_AUDIT_SQL_LOGINS_INFO_DETAILED','DBA_VCC_AUDIT_SQL_SERVER_DEFAULT_LOCATIONS_DETAILED',
    'DBA_VCC_AUDIT_TOP5_TABLES_PER_DATABASE_DETAILED','DBA_VCC_AUDIT_TRACE_FLAGS_DETAILED',
    'DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK','DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT',
    'DBA_VCC_MON_CONNECTION_CHECK','DBA_VCC_MON_Eventlog_CHECK',
    'DBA_VCC_MON_LOCAL_DRIVE_CHECK','DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK',
    'DBA_VCC_MON_SQL_SERVER_INFO_CHECK','DBA_VCC_MON_VLF_COUNT_CHECK',
    'DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED','DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED',
    'DBA_VCC_MYSQL_DAILY_CHECKS','DBA_VCC_MYSQL_MON_PING_STATS',
    'DBA_VCC_MYSQL_MON_SQL_STATUS','DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK',
    'DBA_VCC_MYSQL_WEEKLY_CHECKS',
    'DBA_VCC_COST_Entity_Count_Collection','DBA_VCC_JIRA_MONTHEND_CHECKS',
    'BASELINE_CONNECTIONS','BASELINE_TABLE_SIZES',
    'DBA - AUDIT - KAPP_Schema_details_Capture',
    'DBA - Maintenance - CHECKDB','DBA - Maintenance - History Cleanup',
    'DBA - Maintenance - ReIndex and Statistics - Local',
    'DBA - Maintenance - SQL Backups FULL','DBA - Maintenance - SQL Backups DIFF',
    'DBA - Maintenance - SQL Backups LOG',
    'DBA - SSISStatusCheck'
)
ORDER BY result, name;

-- -----------------------------------------------------------------------------
-- TEST 3: Full state snapshot — compare against T01 baseline
-- No pass/fail — use this to diff against T01 output manually.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 3: Full state snapshot (compare to T01 baseline) ===';
SELECT
    j.name                                              AS job_name,
    CASE j.enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state
FROM msdb.dbo.sysjobs j
ORDER BY j.name;

SELECT
    name                                                AS database_name,
    state_desc                                          AS current_state
FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb')
ORDER BY name;

-- -----------------------------------------------------------------------------
-- TEST 4: DBA_VCC and DBA_VCC_MEMSQL still ONLINE after rollback
-- These must never go offline regardless of rollback scope.
-- PASS: both show ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 4: DBA_VCC and DBA_VCC_MEMSQL still ONLINE ===';
SELECT
    name,
    state_desc,
    CASE state_desc WHEN 'ONLINE' THEN 'PASS' ELSE 'FAIL' END AS result
FROM sys.databases
WHERE name IN ('DBA_VCC','DBA_VCC_MEMSQL')
ORDER BY name;
