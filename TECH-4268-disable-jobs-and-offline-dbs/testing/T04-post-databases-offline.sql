-- =============================================================================
-- T04-post-databases-offline.sql
-- TECH-4268 — Post-change test: after 03-databases-offline.sql
-- Run immediately after 03-databases-offline.sql completes.
-- All checks must show PASS before proceeding to 04-reenable-2fa-job.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TEST 1: 6 target databases are OFFLINE
-- PASS: all 6 show OFFLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 1: Target databases are OFFLINE ===';
SELECT
    name                                                AS database_name,
    state_desc                                          AS current_state,
    CASE state_desc
        WHEN 'OFFLINE' THEN 'PASS'
        ELSE 'FAIL — expected OFFLINE'
    END                                                 AS result
FROM sys.databases
WHERE name IN (
    'DBA_VCC_AWS','DBA_VCC_MYSQL',
    'DBA_VCC_COST','DBA_VCC_ATLASSIAN',
    'KURTOSYS_BASELINE','Utilities'
)
ORDER BY name;

-- -----------------------------------------------------------------------------
-- TEST 2: DBA_VCC is ONLINE (Grafana 2FA connection proxy — must NOT go offline)
-- PASS: state_desc = ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 2: DBA_VCC is ONLINE (2FA connection proxy) ===';
SELECT
    name,
    state_desc,
    CASE state_desc
        WHEN 'ONLINE' THEN 'PASS'
        ELSE 'FAIL — DBA_VCC must stay ONLINE, both 2FA alerts will break'
    END                                                 AS result
FROM sys.databases
WHERE name = 'DBA_VCC';

-- -----------------------------------------------------------------------------
-- TEST 3: DBA_VCC_MEMSQL is ONLINE (2FA job writes to it)
-- PASS: state_desc = ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 3: DBA_VCC_MEMSQL is ONLINE ===';
SELECT
    name,
    state_desc,
    CASE state_desc
        WHEN 'ONLINE' THEN 'PASS'
        ELSE 'FAIL — DBA_VCC_MEMSQL must stay ONLINE'
    END                                                 AS result
FROM sys.databases
WHERE name = 'DBA_VCC_MEMSQL';

-- -----------------------------------------------------------------------------
-- TEST 4: Count — exactly 6 user databases are OFFLINE
-- PASS: offline_count = 6
-- -----------------------------------------------------------------------------
PRINT '=== TEST 4: Offline count = 6 ===';
SELECT
    COUNT(*)                                            AS offline_count,
    CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL — expected 6' END AS result
FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb')
AND state_desc = 'OFFLINE';

-- -----------------------------------------------------------------------------
-- TEST 5: System databases are all ONLINE (sanity check)
-- PASS: all 4 system databases show ONLINE
-- -----------------------------------------------------------------------------
PRINT '=== TEST 5: System databases are ONLINE ===';
SELECT
    name,
    state_desc,
    CASE state_desc WHEN 'ONLINE' THEN 'PASS' ELSE 'FAIL' END AS result
FROM sys.databases
WHERE name IN ('master','model','msdb','tempdb')
ORDER BY name;

-- -----------------------------------------------------------------------------
-- TEST 6: Full database state summary
-- Reference view — no pass/fail, just the complete picture.
-- -----------------------------------------------------------------------------
PRINT '=== TEST 6: Full database state summary ===';
SELECT
    name                                                AS database_name,
    state_desc                                          AS current_state,
    recovery_model_desc                                 AS recovery_model
FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb')
ORDER BY state_desc, name;
