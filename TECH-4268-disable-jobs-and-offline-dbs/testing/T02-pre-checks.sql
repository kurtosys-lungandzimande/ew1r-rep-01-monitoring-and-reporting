-- =============================================================================
-- T02-pre-checks.sql
-- TECH-4268 — Pre-change validation (testing)
-- Run AFTER T01 and BEFORE any change script.
-- All checks must return PASS before proceeding.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PRE-CHECK 1: Grafana 2FA datasource dependency
-- Expected: DBA_VCC is ONLINE (confirmed 2026-09-23 — datasource UID e8597015
-- connects to DBA_VCC; queries use 3-part names to reach DBA_VCC_MEMSQL).
-- PASS: DBA_VCC state_desc = ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== PRE-CHECK 1: DBA_VCC is ONLINE (Grafana 2FA connection proxy) ===';
SELECT
    name,
    state_desc,
    CASE WHEN state_desc = 'ONLINE' THEN 'PASS' ELSE 'FAIL — DBA_VCC must be ONLINE before proceeding' END AS result
FROM sys.databases
WHERE name = 'DBA_VCC';

-- -----------------------------------------------------------------------------
-- PRE-CHECK 2: Final backups — confirm recent FULL backups exist for all
-- databases being taken offline + DBA_VCC_MEMSQL.
-- PASS: each database has a backup_finish_date within the last 24 hours.
-- If any row is missing, run 01-final-backups.sql first.
-- -----------------------------------------------------------------------------
PRINT '=== PRE-CHECK 2: Recent FULL backups exist for all target databases ===';
SELECT
    bs.database_name,
    MAX(bs.backup_finish_date)                          AS latest_backup,
    CASE
        WHEN MAX(bs.backup_finish_date) >= DATEADD(HOUR, -24, GETDATE()) THEN 'PASS'
        ELSE 'FAIL — no backup in last 24 hours, run 01-final-backups.sql'
    END                                                 AS result
FROM msdb.dbo.backupset bs
WHERE bs.database_name IN (
    'DBA_VCC_MEMSQL','DBA_VCC_AWS','DBA_VCC_MYSQL',
    'DBA_VCC','DBA_VCC_COST','DBA_VCC_ATLASSIAN',
    'KURTOSYS_BASELINE','Utilities'
)
AND bs.type = 'D'
GROUP BY bs.database_name
ORDER BY bs.database_name;

-- -----------------------------------------------------------------------------
-- PRE-CHECK 3: No active connections to databases being taken offline.
-- PASS: active_connections = 0 for all target databases.
-- If any show > 0, investigate and kill blocking sessions before proceeding.
-- -----------------------------------------------------------------------------
PRINT '=== PRE-CHECK 3: No active connections to target databases ===';
SELECT
    db.name                                             AS database_name,
    COUNT(sp.spid)                                      AS active_connections,
    CASE
        WHEN COUNT(sp.spid) = 0 THEN 'PASS'
        ELSE 'WARN — active connections exist, review before taking offline'
    END                                                 AS result
FROM sys.databases db
LEFT JOIN sys.sysprocesses sp ON db.database_id = sp.dbid AND sp.spid > 50
WHERE db.name IN (
    'DBA_VCC_AWS','DBA_VCC_MYSQL',
    'DBA_VCC_COST','DBA_VCC_ATLASSIAN','KURTOSYS_BASELINE','Utilities'
)
GROUP BY db.name
ORDER BY db.name;

-- -----------------------------------------------------------------------------
-- PRE-CHECK 4: Q35 — DBA_VCC_MEMSQL_DAILY_CHECKS failure root cause.
-- This is a manual gate. The query shows the last failure detail.
-- PASS: you have confirmed with yogeshwar.phull / tashvir.babulal why the
-- job was disabled on 2026-05-08 and the linked servers are reachable.
-- Do NOT proceed to 04-reenable-2fa-job.sql without this answer.
-- -----------------------------------------------------------------------------
PRINT '=== PRE-CHECK 4: DBA_VCC_MEMSQL_DAILY_CHECKS — last failure detail (Q35) ===';
SELECT TOP 5
    j.name,
    h.run_date,
    h.run_time,
    h.step_id,
    h.step_name,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'In Progress'
    END                                                 AS outcome,
    h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
WHERE j.name = 'DBA_VCC_MEMSQL_DAILY_CHECKS'
ORDER BY h.run_date DESC, h.run_time DESC, h.step_id;

PRINT '>>> MANUAL GATE: Confirm Q35 root cause with yogeshwar.phull / tashvir.babulal before step 04.';

-- -----------------------------------------------------------------------------
-- PRE-CHECK 5: Retained jobs are currently in expected state
-- DBA - Maintenance - SQL Backup EW1P-OCT must be ENABLED.
-- syspolicy_purge_history must be ENABLED.
-- DBA_VCC_MEMSQL_DAILY_CHECKS is expected DISABLED (will be re-enabled in 04).
-- -----------------------------------------------------------------------------
PRINT '=== PRE-CHECK 5: Retained jobs current state ===';
SELECT
    name                                                AS job_name,
    CASE enabled WHEN 1 THEN 'ENABLED' ELSE 'DISABLED' END AS state,
    CASE
        WHEN name = 'DBA_VCC_MEMSQL_DAILY_CHECKS'              AND enabled = 0 THEN 'PASS — will be re-enabled in step 04'
        WHEN name = 'DBA - Maintenance - SQL Backup EW1P-OCT'  AND enabled = 1 THEN 'PASS'
        WHEN name = 'syspolicy_purge_history'                   AND enabled = 1 THEN 'PASS'
        ELSE 'REVIEW — unexpected state'
    END                                                 AS result
FROM msdb.dbo.sysjobs
WHERE name IN (
    'DBA_VCC_MEMSQL_DAILY_CHECKS',
    'DBA - Maintenance - SQL Backup EW1P-OCT',
    'syspolicy_purge_history'
)
ORDER BY name;
