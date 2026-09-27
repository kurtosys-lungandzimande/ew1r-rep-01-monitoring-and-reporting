-- =============================================================================
-- T05-post-2fa-reenable.sql
-- TECH-4268 — Post-change test: after 04-reenable-2fa-job.sql
-- Run AFTER the first successful 06:00 UTC DBA_VCC_MEMSQL_DAILY_CHECKS run
-- (or after a manual trigger — see 04-reenable-2fa-job.sql Step 5).
-- All checks must pass before closing the ticket.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TEST 1: DBA_VCC_MEMSQL_DAILY_CHECKS is ENABLED
-- PASS: state = ENABLED
-- -----------------------------------------------------------------------------
PRINT '=== TEST 1: DBA_VCC_MEMSQL_DAILY_CHECKS is ENABLED ===';
SELECT
    name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    CASE enabled WHEN 1 THEN 'PASS' ELSE 'FAIL — job must be enabled' END AS result
FROM msdb.dbo.sysjobs
WHERE name = 'DBA_VCC_MEMSQL_DAILY_CHECKS';

-- -----------------------------------------------------------------------------
-- TEST 2: Last run of DBA_VCC_MEMSQL_DAILY_CHECKS succeeded
-- PASS: most recent step_id = 0 row shows Succeeded with run_date = today
-- -----------------------------------------------------------------------------
PRINT '=== TEST 2: DBA_VCC_MEMSQL_DAILY_CHECKS last run succeeded ===';
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
    END                                                 AS outcome,
    CASE
        WHEN h.run_status = 1
         AND h.run_date = CAST(CONVERT(varchar(8), GETDATE(), 112) AS int)
        THEN 'PASS'
        WHEN h.run_status = 1 THEN 'PASS (not today — check run_date)'
        ELSE 'FAIL — last run did not succeed'
    END                                                 AS result,
    h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
WHERE j.name = 'DBA_VCC_MEMSQL_DAILY_CHECKS'
  AND h.step_id = 0
ORDER BY h.run_date DESC, h.run_time DESC;

-- -----------------------------------------------------------------------------
-- TEST 3: DBA_VCC_MEMSQL data freshness — compare against T01 baseline
-- PASS: MAX(DateChecked) for BAS_Ping_Stat and BAS_SQL_Status = today
-- -----------------------------------------------------------------------------
PRINT '=== TEST 3: DBA_VCC_MEMSQL data freshness (compare to T01 baseline) ===';
SELECT
    'INFO_ClientSizes_Sizes_FP'     AS table_name,
    MAX(DateChecked)                AS last_data,
    COUNT(*)                        AS row_count,
    CASE WHEN MAX(DateChecked) >= CAST(GETDATE() AS date) THEN 'PASS' ELSE 'STALE — check job run' END AS result
FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT
    'INFO_Client_FP_Detail',
    MAX(DateChecked), COUNT(*),
    CASE WHEN MAX(DateChecked) >= CAST(GETDATE() AS date) THEN 'PASS' ELSE 'STALE' END
FROM DBA_VCC_MEMSQL.dbo.INFO_Client_FP_Detail
UNION ALL
SELECT
    'BAS_Ping_Stat',
    MAX(DATECHECKED), COUNT(*),
    CASE WHEN MAX(DATECHECKED) >= CAST(GETDATE() AS date) THEN 'PASS' ELSE 'STALE' END
FROM DBA_VCC_MEMSQL.dbo.BAS_Ping_Stat
UNION ALL
SELECT
    'BAS_SQL_Status',
    MAX(DATECHECKED), COUNT(*),
    CASE WHEN MAX(DATECHECKED) >= CAST(GETDATE() AS date) THEN 'PASS' ELSE 'STALE' END
FROM DBA_VCC_MEMSQL.dbo.BAS_SQL_Status;

-- -----------------------------------------------------------------------------
-- TEST 4: DBA_VCC is still ONLINE after all changes
-- PASS: state_desc = ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 4: DBA_VCC still ONLINE ===';
SELECT
    name,
    state_desc,
    CASE state_desc WHEN 'ONLINE' THEN 'PASS' ELSE 'FAIL' END AS result
FROM sys.databases
WHERE name = 'DBA_VCC';

-- -----------------------------------------------------------------------------
-- TEST 5: DBA_VCC_MEMSQL still ONLINE
-- PASS: state_desc = ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 5: DBA_VCC_MEMSQL still ONLINE ===';
SELECT
    name,
    state_desc,
    CASE state_desc WHEN 'ONLINE' THEN 'PASS' ELSE 'FAIL' END AS result
FROM sys.databases
WHERE name = 'DBA_VCC_MEMSQL';

-- -----------------------------------------------------------------------------
-- TEST 6: No unexpected job runs or failures since the change window
-- PASS: only DBA - Maintenance - SQL Backup EW1P-OCT, syspolicy_purge_history,
-- and DBA_VCC_MEMSQL_DAILY_CHECKS appear — all with Succeeded outcome.
-- Any other job appearing here is unexpected and must be investigated.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 6: Job runs in last 24 hours — no unexpected failures ===';
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
    END                                                 AS outcome,
    CASE
        WHEN h.run_status = 0 THEN 'INVESTIGATE — job failed'
        WHEN j.name NOT IN (
            'DBA_VCC_MEMSQL_DAILY_CHECKS',
            'DBA - Maintenance - SQL Backup EW1P-OCT',
            'syspolicy_purge_history'
        ) THEN 'UNEXPECTED — job should be disabled'
        ELSE 'OK'
    END                                                 AS result
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
WHERE h.step_id = 0
  AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(DAY, -1, GETDATE())
ORDER BY h.run_date DESC, h.run_time DESC;

-- -----------------------------------------------------------------------------
-- TEST 7: MANUAL — Grafana 2FA alert rules
-- Cannot be automated — must be verified in the Grafana UI.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 7: MANUAL — Grafana 2FA alert rules ===';
PRINT '>>> Open Grafana: https://ew1r-rep-01 > Alerting > Alert rules';
PRINT '>>> KAPP Client Config Alert              — state must be Normal or Pending (not Error/NoData)';
PRINT '>>> KAPP Client Application Auth Config Alert — state must be Normal or Pending (not Error/NoData)';
PRINT '>>> If either shows Error: check DBA_VCC datasource connection and SP execution in DBA_VCC_MEMSQL.';
