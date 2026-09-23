-- =============================================================================
-- 02-disable-jobs.sql
-- EW1R-REP-01 — Disable all non-retained SQL Agent jobs
-- Ticket: TECH-4268
-- Run AFTER 01-final-backups.sql.
-- Nothing is dropped. Every disable is reversible via 06-rollback.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- RETAINED — DO NOT TOUCH (confirmed below for safety)
-- -----------------------------------------------------------------------------
-- DBA_VCC_MEMSQL_DAILY_CHECKS        — 2FA alerting chain (re-enabled in 04)
-- DBA - Maintenance - SQL Backup EW1P-OCT — retained until replacement delivered
-- syspolicy_purge_history             — system job, leave alone
-- DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED  — already disabled, leave off
-- DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE       — already disabled, leave off
-- DBA_VCC_MEMSQL_HOURLY_CHECKS               — already disabled, leave off
-- DBA_VCC_MEMSQL_MON_PING_STATS              — already disabled, leave off
-- DBA_VCC_MEMSQL_MON_SQL_STATUS              — already disabled, leave off
-- DBA_VCC_MEMSQL_WEEKLY_CHECKS               — already disabled, leave off
-- DBA - MemSQL Range Stats Candidates        — already disabled, leave off
-- DBA - ObjectIDValidationReport             — already disabled, leave off
-- DBA - Production Logon Report              — already disabled, leave off
-- DBA - UtilitiesCleanupHistoryTables        — already disabled, leave off
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Group 1: VCC AWS (3 jobs)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_15MIN_CHECKS',  @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_DAILY_CHECKS',  @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_WEEKLY_CHECKS', @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 2: VCC Core (4 jobs)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_DAILY_CHECKS',                        @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_HOURLY_CHECKS',                       @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_WEEKLY_CHECKS',                       @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED', @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 3: VCC Audit Collection (16 jobs)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_BACKUP_INFO_DETAILED',              @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_CREATION',                 @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_INFO_DETAILED',            @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_USERS_DETAILED',           @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DBINFO_DETAILED',                   @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED',           @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_FAILED_LOGIN_SQL_CHECK',            @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_JOB_INFO_DETAILED',                 @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_LOGIN_SQL_CHECK',                   @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_LOW_RUNNING_DRIVES_FILES_DETAILED', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SERVER_RESTART_REQUIRED_DETAILED',  @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_DATABASE_USAGE_DETAILED',       @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_LOGINS_INFO_DETAILED',          @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_SERVER_DEFAULT_LOCATIONS_DETAILED', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_TOP5_TABLES_PER_DATABASE_DETAILED', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_TRACE_FLAGS_DETAILED',              @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 4: VCC Server Monitoring (8 jobs)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK',    @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT',    @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_CONNECTION_CHECK',            @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_Eventlog_CHECK',              @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_LOCAL_DRIVE_CHECK',           @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK',     @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_SQL_SERVER_INFO_CHECK',       @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_VLF_COUNT_CHECK',             @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 5: VCC MySQL / DXM (7 jobs)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED',  @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED',   @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_DAILY_CHECKS',                @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_PING_STATS',              @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_SQL_STATUS',              @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK',       @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_WEEKLY_CHECKS',               @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 6: VCC Cost / Atlassian (2 jobs)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_COST_Entity_Count_Collection', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_JIRA_MONTHEND_CHECKS',         @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 7: Baseline (2 jobs)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'BASELINE_CONNECTIONS',   @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'BASELINE_TABLE_SIZES',   @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 8: KAPP Schema (1 job)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - AUDIT - KAPP_Schema_details_Capture', @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 9: DBA Maintenance (6 jobs — EW1P-OCT backup is RETAINED)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - CHECKDB',                      @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - History Cleanup',               @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - ReIndex and Statistics - Local', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups FULL',              @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups DIFF',              @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups LOG',               @enabled = 0;

-- -----------------------------------------------------------------------------
-- Group 10: SSIS (1 job)
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - SSISStatusCheck', @enabled = 0;

-- -----------------------------------------------------------------------------
-- Confirm: all targeted jobs are now disabled, retained jobs still enabled
-- Expected disabled count: 50
-- Expected still-enabled: DBA_VCC_MEMSQL_DAILY_CHECKS (will be re-enabled in 04),
--                         DBA - Maintenance - SQL Backup EW1P-OCT,
--                         syspolicy_purge_history
-- -----------------------------------------------------------------------------
SELECT
    name                                            AS job_name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state
FROM msdb.dbo.sysjobs
ORDER BY enabled DESC, name;
