-- =============================================================================
-- 00-pre-change-state-capture.sql
-- EW1R-REP-01 — Pre-change state capture
-- Ticket: TECH-4268
-- Run BEFORE any other script in this folder.
-- Save the output — this is your rollback reference.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Section 1: All 63 SQL Agent jobs — current enabled/disabled state
-- -----------------------------------------------------------------------------
SELECT
    j.name                                          AS job_name,
    j.enabled                                       AS is_enabled,
    CASE j.enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    j.date_created,
    j.date_modified,
    ISNULL(jh.last_run_date_fmt, 'Never')           AS last_run_date,
    ISNULL(jh.last_run_outcome_desc, 'Never')       AS last_run_outcome
FROM msdb.dbo.sysjobs j
LEFT JOIN (
    SELECT
        job_id,
        CONVERT(varchar(10),
            CAST(CAST(last_run_date AS varchar(8)) AS date), 120)    AS last_run_date_fmt,
        CASE last_run_outcome
            WHEN 0 THEN 'Failed'
            WHEN 1 THEN 'Succeeded'
            WHEN 2 THEN 'Retry'
            WHEN 3 THEN 'Cancelled'
            ELSE 'Unknown'
        END                                                           AS last_run_outcome_desc
    FROM msdb.dbo.sysjobservers
) jh ON j.job_id = jh.job_id
ORDER BY j.name;

-- -----------------------------------------------------------------------------
-- Section 2: All databases — current online/offline state and recovery model
-- -----------------------------------------------------------------------------
SELECT
    name                                            AS database_name,
    state_desc                                      AS current_state,
    recovery_model_desc                             AS recovery_model,
    CAST(
        (SELECT SUM(CAST(size AS bigint)) * 8.0 / 1024
         FROM sys.master_files mf
         WHERE mf.database_id = d.database_id)
    AS decimal(10,2))                               AS size_mb,
    create_date
FROM sys.databases d
WHERE name NOT IN ('master','model','msdb','tempdb')
ORDER BY name;

-- -----------------------------------------------------------------------------
-- Section 3: Grafana 2FA alert datasource dependency check
-- Confirms which datasource UID the two 2FA alert rules reference.
-- Run this output against grafana.db via xp_cmdshell/Python before proceeding.
-- Expected: both alert rules reference DBA_VCC (UID a082f27e or e8597015).
-- If they reference DBA_VCC_MEMSQL directly, do NOT take DBA_VCC offline
-- until the datasource is repointed.
-- -----------------------------------------------------------------------------
-- NOTE: This query is a reminder — run manually against grafana.db:
--   SELECT title, data FROM dashboard WHERE is_folder = 0
--   AND (data LIKE '%KAPP Client Config Alert%'
--        OR data LIKE '%KAPP Client Application Auth Config Alert%');
PRINT '>>> ACTION REQUIRED: Confirm 2FA alert datasource UID in grafana.db before proceeding.';
PRINT '>>> Expected: both alert rules use DBA_VCC datasource (UID a082f27e or e8597015).';
PRINT '>>> If confirmed, DBA_VCC must stay ONLINE until 2FA alerts are validated post-change.';

-- -----------------------------------------------------------------------------
-- Section 4: DBA_VCC_MEMSQL_DAILY_CHECKS — current state and last run detail
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
    END AS last_run_outcome,
    js.last_run_duration
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.name = 'DBA_VCC_MEMSQL_DAILY_CHECKS';

-- -----------------------------------------------------------------------------
-- Section 5: Snapshot of DBA_VCC_MEMSQL data freshness before re-enable
-- Use this to confirm data starts flowing again after re-enable.
-- -----------------------------------------------------------------------------
SELECT 'INFO_ClientSizes_Sizes_FP'  AS table_name, MAX(DateChecked) AS last_data, COUNT(*) AS row_count FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'INFO_Client_FP_Detail',      MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_Client_FP_Detail
UNION ALL
SELECT 'INFO_KAPP_Workflow_Run_Detail', MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_KAPP_Workflow_Run_Detail
UNION ALL
SELECT 'BAS_Ping_Stat',              MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
UNION ALL
SELECT 'BAS_SQL_Status',             MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status;
