-- =============================================================================
-- 04-reenable-2fa-job.sql
-- EW1R-REP-01 — Re-enable DBA_VCC_MEMSQL_DAILY_CHECKS for 2FA alerting
-- Ticket: TECH-4268
-- Run AFTER 03-databases-offline.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CONTEXT
-- DBA_VCC_MEMSQL_DAILY_CHECKS was disabled on 2026-05-08 12:00:52.
-- Its last run on 2026-05-08 failed (DBA_VCC_MEMSQL_DAILY_CHECKS — Failed).
-- The 2FA alerting chain depends on two steps in this job:
--   - SP_AUDIT_FP_Client_Sizes_DETAILED
--   - SP_AUDIT_FP_Client_ApplicationConfiguration_Auth_DETAILED
-- These steps connect to SingleStore via linked servers and write to
-- DBA_VCC_MEMSQL. The Grafana alert rules then query DBA_VCC_MEMSQL via
-- the DBA_VCC datasource using REP_CLIENT_CONFIG_CHANGES_REPORT and
-- REP_CLIENT_APP_AUTH_CONFIG_CHANGES_REPORT.
--
-- OPEN QUESTION Q35: The root cause of the 8 May 2026 failure has not been
-- confirmed. Re-enabling before understanding the failure risks:
--   - Cascading errors if the linked server targets are unreachable
--   - Data corruption if the failure was mid-write
--   - Repeated failures with no alert firing (no operator wired to this job)
--
-- ACTION REQUIRED before running this script:
--   1. Confirm with yogeshwar.phull / tashvir.babulal why the job was disabled
--      and what caused the 8 May 2026 failure.
--   2. Confirm the SingleStore linked servers the job uses are reachable.
--   3. Review the job step definitions to confirm no dead linked servers
--      are referenced beyond the 2FA steps.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Step 1: Confirm current state before re-enabling
-- -----------------------------------------------------------------------------
SELECT
    j.name,
    j.enabled,
    CASE j.enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END AS last_run_outcome
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.name = 'DBA_VCC_MEMSQL_DAILY_CHECKS';

-- -----------------------------------------------------------------------------
-- Step 2: Confirm DBA_VCC_MEMSQL is ONLINE before re-enabling the job
-- -----------------------------------------------------------------------------
SELECT name, state_desc
FROM sys.databases
WHERE name = 'DBA_VCC_MEMSQL';

-- Expected: state_desc = ONLINE

-- -----------------------------------------------------------------------------
-- Step 3: Re-enable the job
-- *** CONFIRM Q35 IS ANSWERED AND STEPS 1-2 ABOVE ARE CLEAN BEFORE RUNNING ***
-- -----------------------------------------------------------------------------
EXEC msdb.dbo.sp_update_job
    @job_name = 'DBA_VCC_MEMSQL_DAILY_CHECKS',
    @enabled  = 1;

-- -----------------------------------------------------------------------------
-- Step 4: Confirm re-enabled
-- -----------------------------------------------------------------------------
SELECT
    name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state
FROM msdb.dbo.sysjobs
WHERE name = 'DBA_VCC_MEMSQL_DAILY_CHECKS';

-- Expected: ENABLED

-- -----------------------------------------------------------------------------
-- Step 5: Optionally trigger a manual run to validate before the 06:00 schedule
-- Remove the comment block to execute. Monitor job history immediately after.
-- -----------------------------------------------------------------------------
/*
EXEC msdb.dbo.sp_start_job @job_name = 'DBA_VCC_MEMSQL_DAILY_CHECKS';

-- Wait ~2 minutes then check outcome:
SELECT TOP 5
    j.name,
    h.run_date,
    h.run_time,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'In Progress'
    END AS outcome,
    h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
WHERE j.name = 'DBA_VCC_MEMSQL_DAILY_CHECKS'
  AND h.step_id = 0
ORDER BY h.run_date DESC, h.run_time DESC;
*/

-- -----------------------------------------------------------------------------
-- Step 6: After the first successful 06:00 run — confirm data is flowing
-- Compare row counts and MAX(DateChecked) against the baseline captured in
-- 00-pre-change-state-capture.sql Section 5.
-- Expect: MAX(DateChecked) updated to today's date.
-- -----------------------------------------------------------------------------
SELECT 'INFO_ClientSizes_Sizes_FP'     AS table_name, MAX(DateChecked) AS last_data, COUNT(*) AS row_count FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'INFO_Client_FP_Detail',         MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_Client_FP_Detail
UNION ALL
SELECT 'INFO_KAPP_Workflow_Run_Detail',  MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_KAPP_Workflow_Run_Detail
UNION ALL
SELECT 'BAS_Ping_Stat',                 MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
UNION ALL
SELECT 'BAS_SQL_Status',                MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status;
