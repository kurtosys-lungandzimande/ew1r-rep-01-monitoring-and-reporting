-- =============================================================================
-- T03-post-disable-jobs.sql
-- TECH-4268 — Post-change test: after 02-disable-jobs.sql
-- Run immediately after 02-disable-jobs.sql completes.
-- All checks must show PASS before proceeding to 03-databases-offline.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TEST 1: All 50 targeted jobs are DISABLED
-- PASS: every row shows DISABLED
-- -----------------------------------------------------------------------------
PRINT '=== TEST 1: All 50 targeted jobs are DISABLED ===';
SELECT
    name                                                AS job_name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    CASE enabled WHEN 0 THEN 'PASS' ELSE 'FAIL — job should be disabled' END AS result
FROM msdb.dbo.sysjobs
WHERE name IN (
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
-- TEST 2: Count — exactly 50 of the targeted jobs are DISABLED
-- PASS: disabled_count = 50
-- -----------------------------------------------------------------------------
PRINT '=== TEST 2: Disabled count = 50 ===';
SELECT
    COUNT(*)                                            AS disabled_count,
    CASE WHEN COUNT(*) = 50 THEN 'PASS' ELSE 'FAIL — expected 50' END AS result
FROM msdb.dbo.sysjobs
WHERE enabled = 0
AND name IN (
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
);

-- -----------------------------------------------------------------------------
-- TEST 3: Retained jobs are still ENABLED
-- PASS: all 3 retained jobs show ENABLED
-- Note: DBA_VCC_MEMSQL_DAILY_CHECKS is still DISABLED here — re-enabled in step 04
-- -----------------------------------------------------------------------------
PRINT '=== TEST 3: Retained jobs still ENABLED ===';
SELECT
    name                                                AS job_name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    CASE
        WHEN name = 'DBA_VCC_MEMSQL_DAILY_CHECKS'             AND enabled = 0 THEN 'PASS — re-enabled in step 04'
        WHEN name = 'DBA - Maintenance - SQL Backup EW1P-OCT' AND enabled = 1 THEN 'PASS'
        WHEN name = 'syspolicy_purge_history'                  AND enabled = 1 THEN 'PASS'
        ELSE 'FAIL — unexpected state'
    END                                                 AS result
FROM msdb.dbo.sysjobs
WHERE name IN (
    'DBA_VCC_MEMSQL_DAILY_CHECKS',
    'DBA - Maintenance - SQL Backup EW1P-OCT',
    'syspolicy_purge_history'
)
ORDER BY name;

-- -----------------------------------------------------------------------------
-- TEST 4: No job in the retained list was accidentally disabled
-- PASS: 0 rows returned
-- -----------------------------------------------------------------------------
PRINT '=== TEST 4: No retained job accidentally disabled ===';
SELECT
    name                                                AS job_name,
    'FAIL — retained job was disabled'                  AS result
FROM msdb.dbo.sysjobs
WHERE name IN (
    'DBA - Maintenance - SQL Backup EW1P-OCT',
    'syspolicy_purge_history'
)
AND enabled = 0;
-- PASS = 0 rows returned
