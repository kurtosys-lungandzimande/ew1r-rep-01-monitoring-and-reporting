-- ============================================================
-- EW1R-REP-01 — Discovery & Verification Queries
-- All queries are READ-ONLY. No changes are made to any data.
-- Run these in SSMS connected to EW1R-REP-01 to verify findings.
-- ============================================================


-- ============================================================
-- SECTION 1 — SERVER BASICS
-- ============================================================

-- 1.1 Server version, edition, and collation
SELECT
    @@SERVERNAME                            AS server_name,
    SERVERPROPERTY('ProductVersion')        AS version,
    SERVERPROPERTY('ProductLevel')          AS patch_level,
    SERVERPROPERTY('Edition')               AS edition,
    SERVERPROPERTY('Collation')             AS collation,
    SERVERPROPERTY('IsClustered')           AS is_clustered,
    SERVERPROPERTY('IsHadrEnabled')         AS is_ag_enabled;

-- 1.2 All databases with size and recovery model
SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    CAST(SUM(f.size * 8.0 / 1024) AS DECIMAL(10,2))        AS size_mb,
    CAST(SUM(f.size * 8.0 / 1024 / 1024) AS DECIMAL(10,2)) AS size_gb
FROM sys.databases d
JOIN sys.master_files f ON d.database_id = f.database_id
GROUP BY d.name, d.state_desc, d.recovery_model_desc
ORDER BY size_mb DESC;

-- 1.3 Services running on this server
SELECT
    servicename,
    service_account,
    status_desc,
    startup_type_desc
FROM sys.dm_server_services;


-- ============================================================
-- SECTION 2 — SQL AGENT JOBS
-- ============================================================

-- 2.1 All jobs with schedule, last run, and alert target
SELECT
    j.name                                          AS job_name,
    j.enabled,
    ISNULL(s.name, 'No schedule')                   AS schedule_name,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END                                             AS last_outcome,
    ISNULL(n.email_address, 'No alert')             AS alert_target
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules jsch ON j.job_id = jsch.job_id
LEFT JOIN msdb.dbo.sysschedules s ON jsch.schedule_id = s.schedule_id
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysoperators n ON j.notify_email_operator_id = n.id
ORDER BY j.name;

-- 2.2 All job steps with commands (what each job actually does)
SELECT
    j.name      AS job_name,
    j.enabled,
    s.step_id,
    s.step_name,
    s.command,
    s.database_name
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
ORDER BY j.name, s.step_id;

-- 2.3 DBA_VCC_MEMSQL jobs — confirm disabled and last run dates
SELECT
    j.name,
    j.enabled,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        ELSE 'Unknown'
    END AS last_outcome
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.name LIKE '%MEMSQL%'
ORDER BY js.last_run_date DESC;

-- 2.4 DBA_VCC_COST collection job — confirm schedule and last run
SELECT
    j.name,
    j.enabled,
    s.step_name,
    s.command,
    sch.name        AS schedule_name,
    sch.freq_type,
    sch.freq_interval,
    sch.active_start_time,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        ELSE 'Unknown'
    END             AS last_outcome
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
JOIN msdb.dbo.sysjobschedules jsch ON j.job_id = jsch.job_id
JOIN msdb.dbo.sysschedules sch ON jsch.schedule_id = sch.schedule_id
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.name = 'DBA_VCC_COST_Entity_Count_Collection'
ORDER BY s.step_id;

-- 2.5 Recent job history for DBA_VCC_COST collection
SELECT TOP 20
    j.name          AS job_name,
    h.step_name,
    h.run_date,
    h.run_time,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        ELSE 'Other'
    END             AS status
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE j.name = 'DBA_VCC_COST_Entity_Count_Collection'
ORDER BY h.run_date DESC, h.run_time DESC;


-- ============================================================
-- SECTION 3 — ALERT MECHANISMS
-- ============================================================

-- 3.1 SQL Server alert operators
SELECT
    name,
    email_address,
    pager_address
FROM msdb.dbo.sysoperators;

-- 3.2 SQL Server alerts — confirm all have has_notification = 0 (silent)
SELECT
    a.name          AS alert_name,
    a.message_id,
    a.severity,
    a.enabled,
    a.has_notification,
    a.notification_message,
    o.name          AS operator_name,
    o.email_address
FROM msdb.dbo.sysalerts a
LEFT JOIN msdb.dbo.sysnotifications sn ON a.id = sn.alert_id
LEFT JOIN msdb.dbo.sysoperators o ON sn.operator_id = o.id;


-- ============================================================
-- SECTION 4 — LINKED SERVERS
-- ============================================================

-- 4.1 All linked servers
SELECT
    name,
    product,
    provider,
    data_source,
    is_linked
FROM sys.servers
WHERE is_linked = 1
ORDER BY name;

-- 4.2 Linked server login mappings
SELECT
    ls.name         AS linked_server,
    ll.remote_name  AS remote_login,
    ll.uses_self_credential
FROM sys.servers ls
LEFT JOIN sys.linked_logins ll ON ls.server_id = ll.server_id
WHERE ls.is_linked = 1
ORDER BY ls.name;


-- ============================================================
-- SECTION 5 — DBA_VCC_COST DATA FRESHNESS
-- ============================================================

-- 5.1 Confirm weekly collection is running — check last date per entity type
SELECT 'INFO_KAPP_Client_Allocations_Counts'             AS table_name, MAX(DateChecked) AS last_collected, COUNT(*) AS rows FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Allocations_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_Document_Counts',                MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Document_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_Entities_Counts',                MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Entities_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_Users_Counts',                   MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Users_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_Snapshots_Counts',               MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Snapshots_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_TimeSeries_Counts',              MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_TimeSeries_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_HistoricalDatasets_Counts',      MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_HistoricalDatasets_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_Disclaimers_Commentaries_Counts',MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Disclaimers_Commentaries_Counts
UNION ALL
SELECT 'INFO_KAPP_Client_Statstics_Counts',               MAX(DateChecked), COUNT(*) FROM DBA_VCC_COST.dbo.INFO_KAPP_Client_Statstics_Counts
UNION ALL
SELECT 'INFO_AWS_DE_Entity_Cost (STALE)',                  MAX(Period),      COUNT(*) FROM DBA_VCC_COST.dbo.INFO_AWS_DE_Entity_Cost;

-- 5.2 Sample of current client list in DBA_VCC_COST
SELECT TOP 20 * FROM DBA_VCC_COST.dbo.LU_KAPP_ClientList;

-- 5.3 All stored procedures in DBA_VCC_COST
SELECT
    name,
    type_desc,
    create_date,
    modify_date
FROM DBA_VCC_COST.sys.objects
WHERE type IN ('P', 'V', 'U')
ORDER BY type, name;


-- ============================================================
-- SECTION 6 — DBA_VCC_MEMSQL DATA FRESHNESS (CRITICAL)
-- ============================================================

-- 6.1 Confirm when data collection stopped — this feeds the Grafana month-end dashboards
SELECT 'INFO_ClientSizes_Sizes_FP (KAPP)'          AS table_name, MAX(DateChecked) AS last_collected, COUNT(*) AS rows FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'ARC_INFO_ClientSizes_Sizes_FP (KAPP arc)',  MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.ARC_INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'INFO_ClientSizes_Sizes_IP (InvestorPress)', MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_IP
UNION ALL
SELECT 'ARC_INFO_ClientSizes_Sizes_IP (IP arc)',    MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.ARC_INFO_ClientSizes_Sizes_IP;

-- 6.2 All stored procedures in DBA_VCC_MEMSQL — confirm REP_MONTHEND procedures exist
SELECT
    name,
    type_desc,
    create_date,
    modify_date
FROM DBA_VCC_MEMSQL.sys.objects
WHERE type = 'P'
AND name LIKE '%MONTHEND%'
ORDER BY name;


-- ============================================================
-- SECTION 7 — DBA_VCC_AWS DATA FRESHNESS
-- ============================================================

-- 7.1 Confirm KAPP API data is still being collected every 15 minutes
SELECT
    'INFO_AWS_KAPP_Query_API_Detail'    AS table_name,
    MAX(DateChecked)                    AS last_collected,
    COUNT(*)                            AS row_count
FROM DBA_VCC_AWS.dbo.INFO_AWS_KAPP_Query_API_Detail;

-- 7.2 Top tables in DBA_VCC_AWS by size
SELECT
    t.name                                                          AS table_name,
    SUM(p.rows)                                                     AS row_count,
    CAST(SUM(a.total_pages * 8.0 / 1024) AS DECIMAL(10,2))         AS size_mb
FROM DBA_VCC_AWS.sys.tables t
JOIN DBA_VCC_AWS.sys.partitions p ON t.object_id = p.object_id
JOIN DBA_VCC_AWS.sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY size_mb DESC;


-- ============================================================
-- SECTION 8 — MONITORED SERVERS
-- ============================================================

-- 8.1 Active monitored servers
SELECT * FROM DBA_VCC.dbo.LU_Serverlist WHERE Active = 1;

-- 8.2 All monitored servers including inactive
SELECT * FROM DBA_VCC.dbo.LU_Serverlist ORDER BY Active DESC;


-- ============================================================
-- SECTION 9 — GRAFANA (run via xp_cmdshell)
-- These use Python to query the Grafana SQLite database directly
-- ============================================================

-- 9.1 Confirm Grafana is running on port 443
EXEC xp_cmdshell 'netstat -ano | findstr ":443"';

-- 9.2 Confirm grafana.exe process
EXEC xp_cmdshell 'tasklist /FI "PID eq 3844"';

-- 9.3 List all Grafana datasources
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT name, type, url, user FROM data_source").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.4 List all Grafana users and last login
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT login, email, name, is_admin, last_seen_at FROM user").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.5 List all Grafana dashboards
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, created, updated FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.6 List all Grafana folders
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, uid, created, updated FROM dashboard WHERE is_folder=1").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.7 List Grafana alert rules
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, condition, no_data_state, exec_err_state, is_paused, updated FROM alert_rule").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.8 List Grafana alert contact points
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT alertmanager_configuration FROM alert_configuration").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';


-- ============================================================
-- SECTION 10 — INFRASTRUCTURE VERIFICATION
-- ============================================================

-- 10.1 Confirm all listening ports
EXEC xp_cmdshell 'netstat -ano | findstr LISTENING';

-- 10.2 Confirm Zabbix agent is running
EXEC xp_cmdshell 'tasklist /FI "PID eq 5700"';

-- 10.3 Confirm Python location
EXEC xp_cmdshell 'where python';

-- 10.4 Check AWS staging folder
EXEC xp_cmdshell 'dir "C:\DBA_Staging\AWS\" /b';

-- 10.5 Check for AWS credentials file
EXEC xp_cmdshell 'dir "C:\Users\sqlsrv\.aws\" /b';

-- 10.6 Grafana database file size confirmation
EXEC xp_cmdshell 'dir "C:\Program Files\GrafanaLabs\grafana\data\grafana.db"';
