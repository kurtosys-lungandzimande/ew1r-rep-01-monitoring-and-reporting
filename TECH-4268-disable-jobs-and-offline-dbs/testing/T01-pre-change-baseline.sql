-- =============================================================================
-- T01-pre-change-baseline.sql
-- TECH-4268 — Pre-change baseline capture (testing)
-- Run FIRST, before any change script. Save the full output.
-- This output is your T06 rollback comparison reference.
-- =============================================================================

PRINT '=== T01-1: All SQL Agent jobs — current state ===';
SELECT
    j.name                                              AS job_name,
    CASE j.enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    j.date_modified,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Unknown/Never'
    END                                                 AS last_run_outcome,
    js.last_run_date,
    js.last_run_time
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
ORDER BY j.name;

-- -----------------------------------------------------------------------------
PRINT '=== T01-2: All user databases — current state, recovery model, size ===';
SELECT
    name                                                AS database_name,
    state_desc                                          AS current_state,
    recovery_model_desc                                 AS recovery_model,
    CAST(
        (SELECT SUM(CAST(size AS bigint)) * 8.0 / 1024
         FROM sys.master_files mf
         WHERE mf.database_id = d.database_id)
    AS decimal(10,2))                                   AS size_mb
FROM sys.databases d
WHERE name NOT IN ('master','model','msdb','tempdb')
ORDER BY name;

-- -----------------------------------------------------------------------------
PRINT '=== T01-3: DBA_VCC_MEMSQL data freshness baseline ===';
SELECT 'INFO_ClientSizes_Sizes_FP'     AS table_name, MAX(DateChecked) AS last_data, COUNT(*) AS row_count FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'INFO_Client_FP_Detail',         MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_Client_FP_Detail
UNION ALL
SELECT 'INFO_KAPP_Workflow_Run_Detail',  MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_KAPP_Workflow_Run_Detail
UNION ALL
SELECT 'BAS_Ping_Stat',                 MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
UNION ALL
SELECT 'BAS_SQL_Status',                MAX(DATECHECKED), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status;

-- -----------------------------------------------------------------------------
PRINT '=== T01-4: DBA_VCC_MEMSQL_DAILY_CHECKS — current state and last run ===';
SELECT
    j.name,
    CASE j.enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END                                                 AS last_run_outcome
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.name = 'DBA_VCC_MEMSQL_DAILY_CHECKS';

-- -----------------------------------------------------------------------------
PRINT '=== T01-5: Count summary — enabled vs disabled jobs ===';
SELECT
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    COUNT(*)                                            AS job_count
FROM msdb.dbo.sysjobs
GROUP BY enabled
ORDER BY enabled DESC;
-- Save this count — use it to validate T03 after disabling 50 jobs.
