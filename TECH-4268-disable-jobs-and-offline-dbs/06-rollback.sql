-- =============================================================================
-- 06-rollback.sql
-- EW1R-REP-01 — Rollback: reverse any change from this ticket individually
-- Ticket: TECH-4268
-- Each section is independent — run only the section(s) needed.
-- Nothing was dropped — all changes are fully reversible.
-- =============================================================================

-- =============================================================================
-- ROLLBACK A: Bring a specific database back ONLINE
-- Run the relevant section only. Do not bring all databases online unless
-- you are doing a full rollback.
-- =============================================================================

-- --- DBA_VCC_AWS ---
-- ALTER DATABASE DBA_VCC_AWS SET ONLINE;

-- --- DBA_VCC_MYSQL ---
-- ALTER DATABASE DBA_VCC_MYSQL SET ONLINE;

-- --- DBA_VCC ---
-- ALTER DATABASE DBA_VCC SET ONLINE;

-- --- DBA_VCC_COST ---
-- ALTER DATABASE DBA_VCC_COST SET ONLINE;

-- --- DBA_VCC_ATLASSIAN ---
-- ALTER DATABASE DBA_VCC_ATLASSIAN SET ONLINE;

-- --- KURTOSYS_BASELINE ---
-- ALTER DATABASE KURTOSYS_BASELINE SET ONLINE;

-- --- Utilities ---
-- ALTER DATABASE Utilities SET ONLINE;

-- =============================================================================
-- ROLLBACK B: Re-enable a specific SQL Agent job
-- Run the relevant section only.
-- =============================================================================

-- --- VCC AWS ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_15MIN_CHECKS',  @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_DAILY_CHECKS',  @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_WEEKLY_CHECKS', @enabled = 1;

-- --- VCC Core ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_DAILY_CHECKS',                         @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_HOURLY_CHECKS',                        @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_WEEKLY_CHECKS',                        @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED',  @enabled = 1;

-- --- VCC Audit Collection ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_BACKUP_INFO_DETAILED',               @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_CREATION',                  @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_INFO_DETAILED',             @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_USERS_DETAILED',            @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DBINFO_DETAILED',                    @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED',            @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_FAILED_LOGIN_SQL_CHECK',             @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_JOB_INFO_DETAILED',                  @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_LOGIN_SQL_CHECK',                    @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_LOW_RUNNING_DRIVES_FILES_DETAILED',  @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SERVER_RESTART_REQUIRED_DETAILED',   @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_DATABASE_USAGE_DETAILED',        @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_LOGINS_INFO_DETAILED',           @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_SERVER_DEFAULT_LOCATIONS_DETAILED', @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_TOP5_TABLES_PER_DATABASE_DETAILED',  @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_TRACE_FLAGS_DETAILED',               @enabled = 1;

-- --- VCC Server Monitoring ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK',    @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT',    @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_CONNECTION_CHECK',            @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_Eventlog_CHECK',              @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_LOCAL_DRIVE_CHECK',           @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK',     @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_SQL_SERVER_INFO_CHECK',       @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_VLF_COUNT_CHECK',             @enabled = 1;

-- --- VCC MySQL / DXM ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED',  @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED',   @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_DAILY_CHECKS',                @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_PING_STATS',              @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_SQL_STATUS',              @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK',       @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_WEEKLY_CHECKS',               @enabled = 1;

-- --- VCC Cost / Atlassian ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_COST_Entity_Count_Collection', @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_JIRA_MONTHEND_CHECKS',         @enabled = 1;

-- --- Baseline ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'BASELINE_CONNECTIONS',   @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'BASELINE_TABLE_SIZES',   @enabled = 1;

-- --- KAPP Schema ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - AUDIT - KAPP_Schema_details_Capture', @enabled = 1;

-- --- DBA Maintenance ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - CHECKDB',                       @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - History Cleanup',                @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - ReIndex and Statistics - Local', @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups FULL',               @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups DIFF',               @enabled = 1;
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups LOG',                @enabled = 1;

-- --- SSIS ---
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA - SSISStatusCheck', @enabled = 1;

-- =============================================================================
-- ROLLBACK C: Disable DBA_VCC_MEMSQL_DAILY_CHECKS (undo step 04)
-- Only run this if the 2FA job is causing problems and needs to be stopped.
-- =============================================================================
-- EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MEMSQL_DAILY_CHECKS', @enabled = 0;

-- =============================================================================
-- ROLLBACK E: Revert linked server IPs back to hostnames (undo 07-update-linked-server-ips.sql)
-- Only run this AFTER the Route53 VPC association fix is confirmed working.
-- Reverts ew1r-aggr-03 and ew1r-aggr-04 from IP addresses back to DNS hostnames.
-- =============================================================================

/*
EXEC sp_dropserver @server = N'ew1r-aggr-03', @droplogins = 'droplogins';
EXEC sp_addlinkedserver
    @server     = N'ew1r-aggr-03',
    @srvproduct = N'MySQL',
    @provider   = N'MSDASQL',
    @datasrc    = N'ew1r-aggr-03.rel.kurtosys-internal.net';

EXEC sp_dropserver @server = N'ew1r-aggr-04', @droplogins = 'droplogins';
EXEC sp_addlinkedserver
    @server     = N'ew1r-aggr-04',
    @srvproduct = N'MySQL',
    @provider   = N'MSDASQL',
    @datasrc    = N'ew1r-aggr-04.rel.kurtosys-internal.net';

-- Verify
SELECT name, data_source FROM sys.servers
WHERE name IN ('ew1r-aggr-03', 'ew1r-aggr-04');

-- Test
EXEC sp_testlinkedserver N'ew1r-aggr-03';
EXEC sp_testlinkedserver N'ew1r-aggr-04';
*/

-- =============================================================================
-- ROLLBACK D: Full rollback — restore server to pre-change state
-- Brings all databases back online and re-enables all jobs that were
-- enabled before this ticket. Run sections A and B together.
-- Only use this if a complete reversal is needed.
-- =============================================================================

/*
-- Bring all offline databases back online
ALTER DATABASE DBA_VCC_AWS        SET ONLINE;
ALTER DATABASE DBA_VCC_MYSQL      SET ONLINE;
ALTER DATABASE DBA_VCC            SET ONLINE;
ALTER DATABASE DBA_VCC_COST       SET ONLINE;
ALTER DATABASE DBA_VCC_ATLASSIAN  SET ONLINE;
ALTER DATABASE KURTOSYS_BASELINE  SET ONLINE;
ALTER DATABASE Utilities          SET ONLINE;

-- Re-enable all jobs that were enabled before this ticket
-- (jobs that were already disabled before this ticket are NOT re-enabled here)
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_15MIN_CHECKS',                          @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_DAILY_CHECKS',                          @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AWS_WEEKLY_CHECKS',                         @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_DAILY_CHECKS',                              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_HOURLY_CHECKS',                             @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_WEEKLY_CHECKS',                             @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED',      @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_BACKUP_INFO_DETAILED',                @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_CREATION',                   @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_INFO_DETAILED',              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DATABASE_USERS_DETAILED',             @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_DBINFO_DETAILED',                     @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_ERRORLOG_SIZES_DETAILED',             @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_FAILED_LOGIN_SQL_CHECK',              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_JOB_INFO_DETAILED',                   @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_LOGIN_SQL_CHECK',                     @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_LOW_RUNNING_DRIVES_FILES_DETAILED',   @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SERVER_RESTART_REQUIRED_DETAILED',    @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_DATABASE_USAGE_DETAILED',         @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_LOGINS_INFO_DETAILED',            @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_SQL_SERVER_DEFAULT_LOCATIONS_DETAILED', @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_TOP5_TABLES_PER_DATABASE_DETAILED',   @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_AUDIT_TRACE_FLAGS_DETAILED',                @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_BASE_SERVER_MEMORY_CHECK',              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_CHECKS_SERV_DATA_COLLECT',              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_CONNECTION_CHECK',                      @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_Eventlog_CHECK',                        @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_LOCAL_DRIVE_CHECK',                     @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_SQL_DAILY_BACKUPS_CHECK',               @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_SQL_SERVER_INFO_CHECK',                 @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MON_VLF_COUNT_CHECK',                       @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_AUDIT_BACKUP_INFO_DETAILED',          @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED',           @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_DAILY_CHECKS',                        @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_PING_STATS',                      @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_SQL_STATUS',                      @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_MON_SQL_VERSION_CHECK',               @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_MYSQL_WEEKLY_CHECKS',                       @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_COST_Entity_Count_Collection',              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA_VCC_JIRA_MONTHEND_CHECKS',                      @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'BASELINE_CONNECTIONS',                              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'BASELINE_TABLE_SIZES',                              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - AUDIT - KAPP_Schema_details_Capture',         @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - CHECKDB',                       @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - History Cleanup',               @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - ReIndex and Statistics - Local', @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups FULL',              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups DIFF',              @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - Maintenance - SQL Backups LOG',               @enabled = 1;
EXEC msdb.dbo.sp_update_job @job_name = 'DBA - SSISStatusCheck',                             @enabled = 1;
*/
