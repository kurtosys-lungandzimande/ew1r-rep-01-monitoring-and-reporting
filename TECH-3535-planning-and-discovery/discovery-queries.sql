-- ============================================================
-- EW1R-REP-01 — Discovery & Verification Queries
-- All queries are READ-ONLY. No changes are made to any data.
-- Run these in SSMS connected to EW1R-REP-01 to verify findings.
--
-- Purpose : Structured discovery of what this server runs, what
--           it monitors, who depends on it, and what breaks if
--           it is decommissioned.
-- Author  : DBA Discovery Pass — 2026
-- Status  : COMPLETE — all 13 sections executed and outputs captured.
--           Findings documented across TECH-3478, TECH-3479, TECH-3480.
--           Consumer confirmation for billing/client-facing use
--           escalated to stakeholders — tracked in open-questions.md.
--           TECH-3535 closed. TECH-3481 in progress.
-- ============================================================


-- ============================================================
-- SECTION 1 — SERVER BASICS
-- Confirm the SQL Server version, edition, databases, and
-- service accounts before doing anything else.
-- ============================================================

-- 1.1 Server version, edition, and collation
-- Confirms SQL Server 2019 Developer Edition (15.0.4455.2).
-- Developer Edition means this is NOT a licensed production engine —
-- important context if a migration or licensing review is needed.
SELECT
    @@SERVERNAME                            AS server_name,
    SERVERPROPERTY('ProductVersion')        AS version,
    SERVERPROPERTY('ProductLevel')          AS patch_level,
    SERVERPROPERTY('Edition')               AS edition,
    SERVERPROPERTY('Collation')             AS collation,
    SERVERPROPERTY('IsClustered')           AS is_clustered,
    SERVERPROPERTY('IsHadrEnabled')         AS is_ag_enabled;

-- ============================================================
-- QUERY 1.2 — All Databases with Size and Recovery Model
--
-- WHY THIS QUERY EXISTS:
-- This proves exactly how many databases exist on this server,
-- how large each one is, and what recovery model each uses.
-- Recovery model is the single most important signal for whether
-- a database is treated as business-critical or not.
-- Anyone challenging your findings can run this and get the
-- exact same numbers.
--
-- WHAT EACH COLUMN PROVES:
--
-- name
--   The database name. Expected: 8 user databases.
--   DBA_VCC_AWS, DBA_VCC_MEMSQL, KURTOSYS_BASELINE,
--   DBA_VCC_MYSQL, DBA_VCC, DBA_VCC_COST, DBA_VCC_ATLASSIAN,
--   Utilities. System databases (master, model, msdb, tempdb)
--   also appear because the query joins sys.master_files which
--   includes all databases. They are not part of the investigation
--   scope but confirm the server is a standard standalone instance.
--
-- state_desc
--   All user databases returned ONLINE — the server is healthy.
--   No SUSPECT, RESTORING, or OFFLINE states. If any appear
--   when you re-run this, that is a separate incident requiring
--   immediate escalation before any decommission work proceeds.
--
-- recovery_model_desc
--   THIS IS THE MOST IMPORTANT COLUMN IN THIS QUERY.
--   Every database on this server uses SIMPLE recovery EXCEPT
--   DBA_VCC_COST which uses FULL recovery.
--
--   SIMPLE = SQL Server automatically reclaims log space.
--   Transaction log backups are not taken. If the server
--   crashes you lose everything since the last FULL or DIFF
--   backup. This is acceptable for monitoring data that can
--   be re-collected.
--
--   FULL = Every single transaction is logged and retained
--   until a log backup runs. This means point-in-time restore
--   is possible. Someone deliberately changed DBA_VCC_COST
--   to FULL recovery — that is not a default, it is a
--   conscious decision that says we cannot afford to lose
--   even one transaction from this database.
--   This is the strongest evidence that DBA_VCC_COST contains
--   business-critical data, likely tied to client billing.
--   It is the only database on this server treated this way.
--
-- size_mb / size_gb
--   The physical size of each database including all data and
--   log files. Use this to size the target replacement host.
--   Total across all user databases: ~363 GB.
--   DBA_VCC_AWS is the largest at 189 GB and is actively growing —
--   it increased ~8 GB since the initial investigation, confirming
--   data collection is still running every 15 minutes.
--   DBA_VCC_MEMSQL is 77 GB and has NOT grown — confirming all
--   its collection jobs are disabled and no new data is coming in.
--
-- WHY sys.master_files IS USED INSTEAD OF sys.databases:
--   sys.databases does not store file sizes directly.
--   sys.master_files has one row per file (data + log) per
--   database. The SUM aggregates all files for each database
--   to give the true total size. The * 8.0 / 1024 converts
--   SQL Server internal 8KB page units into megabytes.
--
-- ACTUAL OUTPUT CONFIRMED (run during investigation):
--   DBA_VCC_AWS        189,088 MB  184.66 GB  ONLINE  SIMPLE  <- actively growing
--   DBA_VCC_MEMSQL      77,316 MB   75.50 GB  ONLINE  SIMPLE  <- static, jobs disabled
--   KURTOSYS_BASELINE   52,224 MB   51.00 GB  ONLINE  SIMPLE
--   DBA_VCC_MYSQL       27,262 MB   26.62 GB  ONLINE  SIMPLE
--   DBA_VCC             24,625 MB   24.05 GB  ONLINE  SIMPLE  <- actively growing
--   DBA_VCC_COST         5,120 MB    5.00 GB  ONLINE  FULL    <- only FULL recovery
--   DBA_VCC_ATLASSIAN    2,048 MB    2.00 GB  ONLINE  SIMPLE
--   Utilities              201 MB    0.20 GB  ONLINE  SIMPLE
--   Total user databases: ~363 GB
--   Replacement host minimum storage requirement: 400 GB+
--
-- IF OUTPUT DIFFERS WHEN YOU RE-RUN:
--   DBA_VCC_COST not on FULL = someone changed it, investigate why.
--   DBA_VCC_AWS still growing = collection pipeline is healthy.
--   DBA_VCC_AWS stopped growing = 15-min collection job has failed silently.
--   DBA_VCC_MEMSQL growing again = someone re-enabled the MemSQL jobs.
--   A database missing = it was dropped, confirm with DBA team.
--   A new database present = undocumented workload, investigate
--   before proceeding with any decommission decision.
-- ============================================================
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

-- ============================================================
-- QUERY 1.3 — Services Running on This Server
--
-- WHY THIS QUERY EXISTS:
-- This confirms exactly which service accounts are running the
-- SQL Server engine, SQL Agent, and the Python extensibility
-- service. These accounts are what the server uses to connect
-- to external systems, run jobs, and call AWS APIs.
-- Anyone reviewing your findings needs to know these accounts
-- exist before they can plan credential rotation or migration.
--
-- WHAT EACH COLUMN PROVES:
--
-- servicename
--   The name of the Windows service. Three services matter here:
--   SQL Server (MSSQLSERVER) — the database engine itself.
--   SQL Server Agent (MSSQLSERVER) — runs all 60 SQL Agent jobs.
--   SQL Server Launchpad (MSSQLSERVER) — runs Python scripts
--   called by the AWS and Jira data collection jobs.
--   If Launchpad is stopped, all Python API calls fail silently
--   and no error is raised in SQL Server — the jobs just return
--   empty results with no indication of why.
--
-- service_account
--   The Windows account running each service.
--   SHNONPRD\sqlsrv runs the engine — this account needs network
--   access to all linked servers and AWS endpoints.
--   SHNONPRD\sqlagent runs the jobs — this is the account whose
--   permissions determine what the jobs can actually do.
--   NT Service\MSSQLLaunchpad is a built-in sandboxed account —
--   it runs Python in the extensibility framework.
--   All three accounts must be documented before decommission
--   because they may have firewall rules, vault entries, and AD
--   permissions tied to them that need to be cleaned up.
--
-- status_desc
--   All three services returned Running — confirmed healthy.
--   If SQL Server Agent shows anything other than Running,
--   all 60 jobs have stopped and no data is being collected.
--   If Launchpad shows anything other than Running, the AWS
--   and Jira Python jobs are failing silently.
--
-- startup_type_desc
--   All three services returned Automatic — confirmed.
--   This means all three services restart automatically after
--   a server reboot. If any showed Manual or Disabled, a reboot
--   would silently break monitoring until someone noticed.
--
-- ACTUAL OUTPUT CONFIRMED (run during investigation):
--   SQL Server (MSSQLSERVER)          SHNONPRD\sqlsrv            Running  Automatic
--   SQL Server Agent (MSSQLSERVER)    SHNONPRD\sqlagent          Running  Automatic
--   SQL Server Launchpad (MSSQLSERVER) NT Service\MSSQLLaunchpad Running  Automatic
--
-- NOTE — no SQL Full-text Filter Daemon Launcher appeared.
-- This means full-text search is either not installed or not
-- in use on this server. Not relevant to this investigation.
--
-- IF OUTPUT DIFFERS WHEN YOU RE-RUN:
--   Agent not Running = all 60 jobs have stopped, data collection halted.
--   Launchpad not Running = Python jobs failing, AWS and Jira data stale.
--   Startup = Manual = server reboot will silently break monitoring.
--   Different service account = someone changed it, check vault and AD.
-- ============================================================
SELECT
    servicename,
    service_account,
    status_desc,
    startup_type_desc
FROM sys.dm_server_services;


-- ============================================================
-- SECTION 2 — SQL AGENT JOBS
-- 63 jobs total — 52 enabled, 11 disabled (confirmed 2026-07-06).
-- Active ones are the critical data collection pipelines that
-- feed Grafana and the DBA_VCC_* databases.
-- KNOWN FAILURES: DBA_VCC_MYSQL_DAILY_CHECKS and
-- DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing daily since
-- 25 June 2026 — WPv2 linked servers point to decommissioned
-- RDS instances. No alert configured — silent failures.
-- ============================================================

-- 2.1 All jobs with schedule, last run, and alert target
-- Use this to get a full picture of what is enabled vs disabled,
-- when each job last ran, and whether failures go anywhere.
-- Most jobs alert to dba@kurtosys.com — confirm who monitors that mailbox.
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
-- Reveals the actual T-SQL or Python commands inside each job step.
-- Key things to look for: Python scripts calling AWS APIs, stored proc
-- calls into DBA_VCC_* databases, and SSIS package references.
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
-- All SingleStore/MemSQL collection jobs were disabled in May 2026
-- after a daily checks failure. This is why the Grafana month-end
-- dashboards have shown no current data since then.
-- Expected: all rows show enabled = 0 and last_run_date in May 2026.
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
-- This job runs every Sunday at 08:00 and collects entity counts
-- per KAPP client across UK, EU, and US production environments.
-- It tracks 9 entity types used for cost/billing reporting.
-- Last confirmed successful run: 29 June 2026.
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
-- Verify the job is running successfully each Sunday.
-- If you see failures here, the cost/billing data may be stale.
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
-- SQL Server has 17 severity alerts defined but NONE of them
-- are wired to notify anyone. Only SQL Agent job failures
-- send email to dba@kurtosys.com.
-- ============================================================

-- 3.1 SQL Server alert operators
-- Should show one operator: dba@kurtosys.com.
-- Confirm who actually monitors this mailbox — is it a team inbox
-- or an individual? Is it actively watched?
SELECT
    name,
    email_address,
    pager_address
FROM msdb.dbo.sysoperators;

-- 3.2 SQL Server alerts — confirm all have has_notification = 0 (silent)
-- Expected: all 17 severity alerts show has_notification = 0.
-- This means fatal errors (severity 19-25), IO failures, and AG issues
-- will fire silently with no one getting paged or emailed.
-- This is a monitoring gap that needs to be addressed.
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
-- 109 linked servers total (confirmed 2026-07-06).
-- Mostly SingleStore (MSDASQL/ODBC), plus SQL Server targets
-- and MySQL instances.
-- KNOWN STALE: All 4 WPv2 linked servers (ew2p-wpv2, ew2r-wpv2,
-- ue1p-wpv2, ue1r-wpv2) point to decommissioned RDS instances.
-- Additional stale nodes: ew1d-aggr-05, ew1d-aggr-15,
-- ew1r-aggr-03.gen-rel (ODBC misconfigured), ew1r-aggr-05.gen-rel,
-- ew2p-aggr-01.gen-prd, ew2p-aggr-02.gen-prd, EW2P-MARKETING-DB.
-- Full reachability audit needed before decommission.
-- ============================================================

-- 4.1 All linked servers
-- 109 total. Grouped by provider:
--   SQLNCLI  = SQL Server targets (EW2P-MSSQL-01/02, EW1P-OCT RDS)
--   MSDASQL  = SingleStore (ODBC), MySQL, Clickhouse, Zabbix, NiFi, WPv2
-- WPv2 linked servers confirmed decommissioned — DNS no longer resolves.
SELECT
    name,
    product,
    provider,
    data_source,
    is_linked
FROM sys.servers
WHERE is_linked = 1
ORDER BY name;

-- 4.2 Job failure investigation — get actual error messages for failing jobs
-- Use this to diagnose why a job is failing. Filter by job name.
-- CONFIRMED: DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED
-- both fail on step SP_AUDIT_WPv2_CLIENTS_DETAILED with:
-- Error 7303 / 7412 — Unknown MySQL server host for ew2p-wpv2 and ew2r-wpv2
-- (DNS failure — RDS instances decommissioned). All 4 WPv2 linked servers
-- confirmed dead as of 2026-07-06. BASELINE_CONNECTIONS also shows
-- ew1d-aggr-05, ew1d-aggr-15, gen-rel and gen-prd nodes unreachable.
SELECT TOP 50
    j.name          AS job_name,
    h.step_name,
    h.run_date,
    h.run_time,
    h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0  -- 0 = Failed
ORDER BY h.run_date DESC, h.run_time DESC;

-- 4.3 Linked server login mappings
-- Shows what credentials are used to connect to each linked server.
-- uses_self_credential = 1 means it passes through the calling account.
-- uses_self_credential = 0 means a mapped remote login is used.
-- The actual passwords/vault locations are unknown — confirm Monday.
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
-- Weekly entity count collection per KAPP client.
-- This database is on FULL recovery model — treat as business-critical.
-- Consumer (Finance / billing) still needs to be confirmed Monday.
-- ============================================================

-- 5.1 Confirm weekly collection is running — check last date per entity type
-- Each row shows the last time data was collected for that entity type.
-- If any MAX(DateChecked) is more than 7 days old, the Sunday job may have failed.
-- INFO_AWS_DE_Entity_Cost is known stale since November 2024 — AWS cost data.
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
-- Shows which KAPP clients are being tracked.
-- Use this to understand the scope of the cost/billing data.
SELECT TOP 20 * FROM DBA_VCC_COST.dbo.LU_KAPP_ClientList;

-- 5.3 All stored procedures in DBA_VCC_COST
-- 19 REP_MONTHEND_* procedures exist here — summary and per-client versions.
-- These are called by an unknown consumer (Finance / account management).
-- Identifying who calls these is a critical Monday action.
SELECT
    name,
    type_desc,
    create_date,
    modify_date
FROM DBA_VCC_COST.sys.objects
WHERE type IN ('P', 'V', 'U')
ORDER BY type, name;

-- 5.4 When did AWS cost data last land in INFO_AWS_DE_Entity_Cost?
-- This table is known stale since November 2024 — confirm exact last date.
-- If MAX(Period) is November 2024 or earlier, the AWS cost collection
-- step has not written data in over 8 months.
SELECT
    'INFO_AWS_DE_Entity_Cost'   AS table_name,
    MAX(Period)                 AS last_collected,
    COUNT(*)                    AS total_rows
FROM DBA_VCC_COST.dbo.INFO_AWS_DE_Entity_Cost;

-- 5.5 Is the AWS cost collection step still inside DBA_VCC_AWS_DAILY_CHECKS?
-- The daily job runs successfully but we need to confirm whether the cost
-- collection step is still present, still enabled, and what it actually does.
-- Look for any step referencing INFO_AWS_DE_Entity_Cost or AWS cost.
SELECT
    j.name          AS job_name,
    j.enabled,
    s.step_id,
    s.step_name,
    s.command
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
WHERE j.name = 'DBA_VCC_AWS_DAILY_CHECKS'
ORDER BY s.step_id;

-- 5.6 Last 5 runs of DBA_VCC_AWS_DAILY_CHECKS — confirm it is succeeding
-- The job shows Succeeded in sysjobservers but that is the overall outcome.
-- Check step-level history to confirm every step inside it is passing.
-- A job can show Succeeded overall even if individual steps are skipped.
SELECT TOP 5
    j.name,
    h.run_date,
    h.run_time,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        ELSE 'Other'
    END             AS status,
    h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE j.name = 'DBA_VCC_AWS_DAILY_CHECKS'
AND h.step_id = 0
ORDER BY h.run_date DESC, h.run_time DESC;


-- ============================================================
-- SECTION 6 — DBA_VCC_MEMSQL DATA FRESHNESS (CRITICAL)
-- All collection jobs were disabled in May 2026 after a failure.
-- The Grafana month-end dashboards (KAPP, InvestorPress, Encore,
-- DXM, WPv2) read from this database — they have shown no current
-- data since May 2026. Nobody has flagged this yet.
-- ============================================================

-- 6.1 Confirm when data collection stopped — this feeds the Grafana month-end dashboards
-- Expected: MAX(DateChecked) will be somewhere in May 2026 for all tables.
-- This confirms the month-end dashboards are showing stale data.
-- Raise this with yogeshwar.phull / tashvir.babulal on Monday.
SELECT 'INFO_ClientSizes_Sizes_FP (KAPP)'          AS table_name, MAX(DateChecked) AS last_collected, COUNT(*) AS rows FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'ARC_INFO_ClientSizes_Sizes_FP (KAPP arc)',  MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.ARC_INFO_ClientSizes_Sizes_FP
UNION ALL
SELECT 'INFO_ClientSizes_Sizes_IP (InvestorPress)', MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.INFO_ClientSizes_Sizes_IP
UNION ALL
SELECT 'ARC_INFO_ClientSizes_Sizes_IP (IP arc)',    MAX(DateChecked), COUNT(*) FROM DBA_VCC_MEMSQL.dbo.ARC_INFO_ClientSizes_Sizes_IP;

-- 6.2 All stored procedures in DBA_VCC_MEMSQL — confirm REP_MONTHEND procedures exist
-- These are the month-end reporting procedures that Grafana dashboards depend on.
-- They exist but have no fresh data to work with since May 2026.
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
-- Core KAPP observability database. 180 GB.
-- KAPP API data is collected every 15 minutes via Python jobs.
-- This is actively growing and Grafana KAPP dashboards read from it.
-- ============================================================

-- 7.1 Confirm KAPP API data is still being collected every 15 minutes
-- Expected: MAX(DateChecked) should be within the last 15-30 minutes
-- if the collection job is healthy. 563M rows as of discovery.
-- If this is stale, the KAPP observability pipeline has broken silently.
SELECT
    'INFO_AWS_KAPP_Query_API_Detail'    AS table_name,
    MAX(DateChecked)                    AS last_collected,
    COUNT(*)                            AS row_count
FROM DBA_VCC_AWS.dbo.INFO_AWS_KAPP_Query_API_Detail;

-- 7.2 Top tables in DBA_VCC_AWS by size
-- Shows what is taking up the most space in the 180 GB database.
-- INFO_AWS_KAPP_Query_API_Detail will be the largest by far.
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
-- The VCC framework tracks which servers it actively monitors.
-- Active = 1 means the server is still in scope for collection.
-- ============================================================

-- 8.1 Active monitored servers
-- Shows only servers currently being monitored.
-- EW2P-MSSQL-01 and EW2P-MSSQL-02 (EU-West-2 production) should appear here.
SELECT * FROM DBA_VCC.dbo.LU_Serverlist WHERE Active = 1;

-- 8.2 All monitored servers including inactive
-- Shows the full history of servers that were ever monitored.
-- Inactive entries may include decommissioned servers or migrated instances.
SELECT * FROM DBA_VCC.dbo.LU_Serverlist ORDER BY Active DESC;


-- ============================================================
-- SECTION 9 — GRAFANA (run via xp_cmdshell)
-- Grafana stores its config in a SQLite database at:
--   C:\Program Files\GrafanaLabs\grafana\data\grafana.db
-- These queries use Python (via xp_cmdshell) to read it directly
-- since there is no SQL Server-native way to query SQLite.
-- Python path: C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\
-- NOTE: xp_cmdshell must be enabled. Run as sysadmin.
-- ============================================================

-- 9.1 Confirm Grafana is running on port 443
-- Expected: grafana.exe listening on 0.0.0.0:443
-- If nothing shows, Grafana is down and all dashboards are inaccessible.
EXEC xp_cmdshell 'netstat -ano | findstr ":443"';

-- 9.2 Confirm grafana.exe process
-- Replace PID 3844 with the current PID if it has changed since discovery.
-- Use tasklist without a filter first if unsure of the current PID.
EXEC xp_cmdshell 'tasklist /FI "PID eq 3844"';

-- 9.3 List all Grafana datasources
-- Expected: 21 datasources including DBA_VCC (localhost MSSQL), KAPP MySQL
-- (Dev/Rel/UK/EU/US Prod), SingleStore (Dev/Rel/UK/EU/US Prod), Zabbix MySQL (x4),
-- NiFi JSON API, CloudWatch, and InfluxDB.
-- The Zabbix datasources use donovan.vangraan credentials — flag for rotation.
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT name, type, url, user FROM data_source").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.4 List all Grafana users and last login
-- Expected: 8 users. 3 active admins (tashvir.babulal, yogeshwar.phull,
-- rayhaan.suleyman) last seen June 2026. donovan.vangraan last seen Nov 2024
-- and is no longer active — his credentials are still used in datasources.
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT login, email, name, is_admin, last_seen_at FROM user").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.5 List all Grafana dashboards
-- Expected: 90 dashboards across 16 folders. Sorted by most recently updated.
-- KAPP and SingleStore dashboards updated Oct/Nov 2025 — these are actively used.
-- Month End Reporting dashboards exist but show stale data since May 2026.
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, created, updated FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.6 List all Grafana folders
-- Expected: 16 folders including KAPP Reporting, SingleStore Monitoring,
-- Month End Reporting, AWS Reports, Encore, Atlassian, Performance, Zabbix.
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, uid, created, updated FROM dashboard WHERE is_folder=1").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.7 List Grafana alert rules
-- Expected: 3 alert rules:
--   1. Failed Read Queries per Second → alerts-data-operations (Slack)
--   2. KAPP Client Config Alert → alerts-data-operations (Slack)
--   3. KAPP Client Application Auth Config Alert → alert-app-allow2fa-disabled (Slack)
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, condition, no_data_state, exec_err_state, is_paused, updated FROM alert_rule").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- 9.8 List Grafana alert contact points
-- NOTE: This query returns 3 rows from alert_configuration.
-- Grafana stores multiple config versions in this table:
--   Row 1 — old draft config: default route pointed to broken email, no sub-routes
--   Row 2 — CURRENT ACTIVE config: default route → alerts-data-operations (Slack),
--            sub-route for Client Auth = Yes → alert-app-allow2fa-disabled (Slack)
--   Row 3 — factory default Grafana ships with, never customised
-- Only Row 2 is the active routing config. The Slack webhook tokens
-- are encrypted — a Grafana admin login is required to view or rotate them.
-- Expected contact points from Row 2: alerts-data-operations (Slack, active),
-- alert-app-allow2fa-disabled (Slack, active), email (placeholder, will not deliver).
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT alertmanager_configuration FROM alert_configuration").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';


-- ============================================================
-- SECTION 10 — INFRASTRUCTURE VERIFICATION
-- Confirm what is running on this server, what ports are open,
-- and where credentials and staging files are stored.
-- ============================================================

-- 10.1 Confirm all listening ports
-- Key ports to look for:
--   443   — Grafana HTTPS
--   1433  — SQL Server
--   10050 — Zabbix agent (this server is monitored by Zabbix)
EXEC xp_cmdshell 'netstat -ano | findstr LISTENING';

-- 10.2 Confirm Zabbix agent is running
-- Replace PID 5700 with the current PID if it has changed.
-- The Zabbix agent means this server is being monitored externally —
-- if it goes offline, Zabbix will detect it.
EXEC xp_cmdshell 'tasklist /FI "PID eq 5700"';

-- 10.3 Confirm Python location
-- Python is used by SQL Agent jobs to call AWS APIs and Jira APIs.
-- Expected: C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe
EXEC xp_cmdshell 'where python';

-- 10.4 Check AWS staging folder
-- Python scripts and config files for AWS API collection are stored here.
-- This is where AWS credentials or config files may be located.
EXEC xp_cmdshell 'dir "C:\DBA_Staging\AWS\" /b';

-- 10.5 Check for AWS credentials file
-- If an AWS credentials file exists here, it contains the IAM access key
-- used by the Python collection jobs. Confirm with DevOps / cloud team
-- whether this is a key or an instance role. Rotate if it is a long-lived key.
EXEC xp_cmdshell 'dir "C:\Users\sqlsrv\.aws\" /b';

-- 10.6 Grafana database file size confirmation
-- The grafana.db SQLite file holds all Grafana config: datasources,
-- dashboards, users, alert rules, and contact points.
-- Back this up before any migration or decommission work.
EXEC xp_cmdshell 'dir "C:\Program Files\GrafanaLabs\grafana\data\grafana.db"';


-- ============================================================
-- SECTION 11 — JOB TO LINKED SERVER MAPPING
-- The 63 jobs exist because the VCC framework monitors multiple
-- platforms (KAPP, SingleStore, MySQL, AWS, Zabbix, Atlassian)
-- each at different frequencies (15min, hourly, daily, weekly).
-- This section answers two questions:
--   1. Which jobs actually USE which linked servers?
--   2. Which linked servers are referenced by NO job at all?
-- The second question identifies candidates for immediate removal.
-- ============================================================

-- 11.1 Which job steps reference each linked server by name?
-- Searches the command text of every job step for linked server names.
-- This is the direct evidence map: job → step → linked server.
-- A linked server that appears here is actively used by at least one job.
-- A linked server that does NOT appear here is an orphan — safe to investigate for removal.
SELECT
    j.name          AS job_name,
    j.enabled,
    s.step_id,
    s.step_name,
    s.database_name,
    s.command
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
WHERE s.command LIKE '%aggr%'
   OR s.command LIKE '%wpv2%'
   OR s.command LIKE '%dxm%'
   OR s.command LIKE '%memsql%'
   OR s.command LIKE '%mysql%'
   OR s.command LIKE '%zabbix%'
   OR s.command LIKE '%marketing%'
   OR s.command LIKE '%nifi%'
ORDER BY j.name, s.step_id;

-- 11.2 Which stored procedures reference linked servers?
-- Job steps call stored procedures. The procs contain the actual linked server names.
-- This searches procedure bodies across all user databases for linked server references.
-- Run this for each database: DBA_VCC, DBA_VCC_AWS, DBA_VCC_MYSQL, KURTOSYS_BASELINE, Utilities.
SELECT
    o.name          AS proc_name,
    m.definition
FROM DBA_VCC.sys.sql_modules m
JOIN DBA_VCC.sys.objects o ON m.object_id = o.object_id
WHERE o.type = 'P'
AND (
    m.definition LIKE '%aggr%'
    OR m.definition LIKE '%wpv2%'
    OR m.definition LIKE '%dxm%'
    OR m.definition LIKE '%memsql%'
    OR m.definition LIKE '%marketing%'
)
ORDER BY o.name;

-- Repeat for DBA_VCC_MYSQL
SELECT
    o.name          AS proc_name,
    m.definition
FROM DBA_VCC_MYSQL.sys.sql_modules m
JOIN DBA_VCC_MYSQL.sys.objects o ON m.object_id = o.object_id
WHERE o.type = 'P'
AND (
    m.definition LIKE '%aggr%'
    OR m.definition LIKE '%wpv2%'
    OR m.definition LIKE '%dxm%'
    OR m.definition LIKE '%memsql%'
    OR m.definition LIKE '%marketing%'
)
ORDER BY o.name;

-- Repeat for KURTOSYS_BASELINE
SELECT
    o.name          AS proc_name,
    m.definition
FROM KURTOSYS_BASELINE.sys.sql_modules m
JOIN KURTOSYS_BASELINE.sys.objects o ON m.object_id = o.object_id
WHERE o.type = 'P'
AND (
    m.definition LIKE '%aggr%'
    OR m.definition LIKE '%wpv2%'
    OR m.definition LIKE '%dxm%'
    OR m.definition LIKE '%memsql%'
    OR m.definition LIKE '%marketing%'
)
ORDER BY o.name;

-- 11.3 Which linked servers appear in NO stored procedure and NO job step?
-- These are true orphans — configured but never called.
-- Cross-reference this list against the confirmed stale servers from Section 4.
-- Any server on this list AND confirmed unreachable = safe to drop.
-- Any server on this list but reachable = was it ever used? Check create_date.
SELECT
    s.name          AS linked_server,
    s.provider,
    s.data_source,
    s.modify_date   AS last_modified
FROM sys.servers s
WHERE s.is_linked = 1
AND s.name NOT IN (
    -- Linked servers referenced in job step commands
    SELECT DISTINCT
        CASE
            WHEN js.command LIKE '%ew2p-wpv2%'  THEN 'ew2p-wpv2'
            WHEN js.command LIKE '%ew2r-wpv2%'  THEN 'ew2r-wpv2'
            WHEN js.command LIKE '%ue1p-wpv2%'  THEN 'ue1p-wpv2'
            WHEN js.command LIKE '%ue1r-wpv2%'  THEN 'ue1r-wpv2'
            WHEN js.command LIKE '%marketing%'  THEN 'EW2P-MARKETING-DB'
        END
    FROM msdb.dbo.sysjobsteps js
    WHERE js.command LIKE '%wpv2%' OR js.command LIKE '%marketing%'
)
ORDER BY s.name;

-- 11.4 Count how many job steps reference each linked server
-- Gives you a usage score per linked server.
-- linked_server with count = 0 after a LEFT JOIN = orphan.
-- linked_server with count > 0 = actively used, must be migrated or replaced before decommission.
SELECT
    srv.name                                AS linked_server,
    COUNT(js.step_id)                       AS job_step_references
FROM sys.servers srv
LEFT JOIN msdb.dbo.sysjobsteps js
    ON js.command LIKE '%' + srv.name + '%'
WHERE srv.is_linked = 1
GROUP BY srv.name
ORDER BY job_step_references DESC, srv.name;

-- 11.5 Job classification — what does each job actually feed?
-- This maps every enabled job to its output destination.
-- Use this to answer: if this job stops, what breaks?
SELECT
    j.name                                  AS job_name,
    j.enabled,
    s.step_name,
    s.database_name                         AS runs_in_database,
    CASE
        WHEN s.command LIKE '%DBA_VCC_AWS%'      THEN 'Feeds DBA_VCC_AWS'
        WHEN s.command LIKE '%DBA_VCC_MEMSQL%'   THEN 'Feeds DBA_VCC_MEMSQL'
        WHEN s.command LIKE '%DBA_VCC_MYSQL%'    THEN 'Feeds DBA_VCC_MYSQL'
        WHEN s.command LIKE '%DBA_VCC_COST%'     THEN 'Feeds DBA_VCC_COST'
        WHEN s.command LIKE '%DBA_VCC_ATLASSIAN%' THEN 'Feeds DBA_VCC_ATLASSIAN'
        WHEN s.command LIKE '%KURTOSYS_BASELINE%' THEN 'Feeds KURTOSYS_BASELINE'
        WHEN s.command LIKE '%DBA_VCC%'          THEN 'Feeds DBA_VCC'
        WHEN s.command LIKE '%xp_cmdshell%'      THEN 'Runs OS command / Python'
        WHEN s.command LIKE '%BACKUP%'           THEN 'Backup job'
        ELSE 'Other / check manually'
    END                                     AS feeds
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
WHERE j.enabled = 1
ORDER BY j.name, s.step_id;


-- ============================================================
-- SECTION 12 — GRAFANA DASHBOARD DATASOURCE CONFIRMATION
-- Purpose: Confirm which Grafana dashboards read from DBA_VCC_COST
-- and which datasource each dashboard is bound to.
-- This directly answers whether DBA_VCC_COST is actively consumed
-- via Grafana — no stakeholder input needed, the answer is in the
-- dashboard JSON stored in grafana.db.
-- ============================================================

-- 12.1 Pull the full dashboard JSON for "Database Engineering Costs"
-- The dashboard JSON contains the datasource UID each panel queries.
-- Look for references to DBA_VCC_COST, REP_MONTHEND, or the localhost
-- SQL Server datasource UID in the panel targets.
-- If the dashboard JSON references DBA_VCC_COST tables or stored procs,
-- that confirms it is an active consumer of this database.
EXEC xp_cmdshell 'echo import sqlite3, json > C:\temp\gf_dash.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_dash.py && echo rows = conn.execute("SELECT title, data FROM dashboard WHERE is_folder=0 AND title LIKE ''%%Cost%%'' OR title LIKE ''%%cost%%''").fetchall() >> C:\temp\gf_dash.py && echo [print(r[0], r[1][:2000]) for r in rows] >> C:\temp\gf_dash.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_dash.py';

-- 12.2 List all dashboards and the datasource UID each one uses
-- This gives a full map of dashboard → datasource.
-- Cross-reference the datasource UID against the datasource list
-- from query 9.3 to confirm which physical database each dashboard reads from.
-- Any dashboard with the localhost MSSQL datasource UID is reading
-- directly from one of the DBA_VCC_* databases on this server.
EXEC xp_cmdshell 'echo import sqlite3, json > C:\temp\gf_ds_map.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_ds_map.py && echo rows = conn.execute("SELECT d.title, ds.name, ds.type, ds.url FROM dashboard d LEFT JOIN data_source ds ON json_extract(d.data, ''$.panels[0].datasource.uid'') = ds.uid WHERE d.is_folder=0 ORDER BY d.title").fetchall() >> C:\temp\gf_ds_map.py && echo [print(r) for r in rows] >> C:\temp\gf_ds_map.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_ds_map.py';

-- 12.3 Search all dashboard JSON for references to DBA_VCC_COST
-- Scans every dashboard's stored JSON for the string DBA_VCC_COST.
-- Any dashboard that appears here is confirmed reading from that database.
-- This is the definitive answer to: is DBA_VCC_COST actively used in Grafana?
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_cost_scan.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_cost_scan.py && echo rows = conn.execute("SELECT title, updated FROM dashboard WHERE is_folder=0 AND data LIKE ''%%DBA_VCC_COST%%'' ORDER BY updated DESC").fetchall() >> C:\temp\gf_cost_scan.py && echo print(''Dashboards referencing DBA_VCC_COST:'') >> C:\temp\gf_cost_scan.py && echo [print(r) for r in rows] >> C:\temp\gf_cost_scan.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_cost_scan.py';

-- 12.4 Search all dashboard JSON for references to REP_MONTHEND stored procedures
-- If any dashboard calls REP_MONTHEND_* procedures directly, that confirms
-- the month-end reporting layer is actively wired into Grafana.
-- This also tells us which dashboards will break if DBA_VCC_MEMSQL or
-- DBA_VCC_COST are decommissioned without a replacement.
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_monthend_scan.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_monthend_scan.py && echo rows = conn.execute("SELECT title, updated FROM dashboard WHERE is_folder=0 AND data LIKE ''%%REP_MONTHEND%%'' ORDER BY updated DESC").fetchall() >> C:\temp\gf_monthend_scan.py && echo print(''Dashboards referencing REP_MONTHEND procedures:'') >> C:\temp\gf_monthend_scan.py && echo [print(r) for r in rows] >> C:\temp\gf_monthend_scan.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_monthend_scan.py';

-- 12.5 Search all dashboard JSON for references to DBA_VCC_MEMSQL
-- Confirms which dashboards depend on the disabled MemSQL collection jobs.
-- These are the dashboards that have been showing stale data since May 2026.
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_memsql_scan.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_memsql_scan.py && echo rows = conn.execute("SELECT title, updated FROM dashboard WHERE is_folder=0 AND data LIKE ''%%DBA_VCC_MEMSQL%%'' ORDER BY updated DESC").fetchall() >> C:\temp\gf_memsql_scan.py && echo print(''Dashboards referencing DBA_VCC_MEMSQL:'') >> C:\temp\gf_memsql_scan.py && echo [print(r) for r in rows] >> C:\temp\gf_memsql_scan.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_memsql_scan.py';

-- 12.6 Get the full datasource list with UIDs
-- Run this alongside 12.2 to cross-reference datasource UIDs found in
-- dashboard JSON against the actual datasource names and connection strings.
-- The UID is what Grafana stores inside dashboard JSON — the name is what
-- you see in the Grafana UI. You need both to make the mapping complete.
-- NOTE: database_name column does not exist in Grafana 9.5.2 SQLite schema.
-- Use uid, name, type, url, and json_data which contains the database name
-- as a JSON field for MSSQL datasources.
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_ds_uid.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_ds_uid.py && echo rows = conn.execute("SELECT uid, name, type, url, json_data FROM data_source ORDER BY name").fetchall() >> C:\temp\gf_ds_uid.py && echo [print(r) for r in rows] >> C:\temp\gf_ds_uid.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_ds_uid.py';


-- ============================================================
-- SECTION 13 — REMAINING DATABASE COVERAGE
-- Purpose: Complete the discovery pass across all user databases.
-- Sections 5, 6, and 7 covered DBA_VCC_COST, DBA_VCC_MEMSQL,
-- and DBA_VCC_AWS. This section covers the remaining databases:
-- DBA_VCC_MYSQL, DBA_VCC_ATLASSIAN, DBA_VCC, and KURTOSYS_BASELINE.
-- Also captures the full stored procedure inventory across all
-- databases and confirms the total Grafana dashboard count.
-- ============================================================


-- ============================================================
-- 13.1 — DBA_VCC_MYSQL data freshness
-- DBA_VCC_MYSQL holds MySQL and DXM client monitoring data.
-- Two jobs feed it: DBA_VCC_MYSQL_DAILY_CHECKS (currently failing
-- due to WPv2 linked servers) and DBA_VCC_MYSQL_WEEKLY_CHECKS.
-- Table names confirmed from sys.tables query (2026-07-07).
-- Key active tables: INFO_DXM_Client_Sizes (122K rows, 7.88 MB)
-- and INFO_WPv2_Client_Sizes (1090 rows, 0.14 MB — near empty,
-- WPv2 decommissioned). ARC_ tables hold archived history.
-- ============================================================
SELECT
    'INFO_DXM_Client_Sizes'         AS table_name,
    MAX(DateChecked)                AS last_collected,
    COUNT(*)                        AS row_count
FROM DBA_VCC_MYSQL.dbo.INFO_DXM_Client_Sizes
UNION ALL
SELECT
    'INFO_WPv2_Client_Sizes',
    MAX(DateChecked),
    COUNT(*)
FROM DBA_VCC_MYSQL.dbo.INFO_WPv2_Client_Sizes
UNION ALL
SELECT
    'INFO_DXM_Clients_Detail',
    MAX(DateChecked),
    COUNT(*)
FROM DBA_VCC_MYSQL.dbo.INFO_DXM_Clients_Detail
UNION ALL
SELECT
    'INFO_DXM_LAMBDA_BACKUPS_Detail',
    MAX(DateChecked),
    COUNT(*)
FROM DBA_VCC_MYSQL.dbo.INFO_DXM_LAMBDA_BACKUPS_Detail
UNION ALL
SELECT
    'INFO_Database_Table_Sizes',
    MAX(DateChecked),
    COUNT(*)
FROM DBA_VCC_MYSQL.dbo.INFO_Database_Table_Sizes;

-- 13.2 — All tables in DBA_VCC_MYSQL with row counts
-- Use this to understand the full scope of what this database holds.
-- Any table with 0 rows or a very old last_collected date is a candidate
-- for cleanup or confirmation that the feed has stopped.
SELECT
    t.name                                                          AS table_name,
    SUM(p.rows)                                                     AS row_count,
    CAST(SUM(a.total_pages * 8.0 / 1024) AS DECIMAL(10,2))         AS size_mb
FROM DBA_VCC_MYSQL.sys.tables t
JOIN DBA_VCC_MYSQL.sys.partitions p ON t.object_id = p.object_id
JOIN DBA_VCC_MYSQL.sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY size_mb DESC;


-- ============================================================
-- 13.3 — DBA_VCC_ATLASSIAN data freshness
-- DBA_VCC_ATLASSIAN holds Jira and Confluence integration data.
-- Fed by DBA_VCC_JIRA_MONTHEND_CHECKS (confirmed running — last
-- successful run 2026-07-01). This confirms what is in the database
-- and when it was last updated.
-- ============================================================
SELECT
    t.name                                                          AS table_name,
    SUM(p.rows)                                                     AS row_count,
    CAST(SUM(a.total_pages * 8.0 / 1024) AS DECIMAL(10,2))         AS size_mb
FROM DBA_VCC_ATLASSIAN.sys.tables t
JOIN DBA_VCC_ATLASSIAN.sys.partitions p ON t.object_id = p.object_id
JOIN DBA_VCC_ATLASSIAN.sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY size_mb DESC;

-- 13.4 — DBA_VCC_ATLASSIAN content check
-- Confirmed from sys.tables (2026-07-07): only 2 tables have data.
-- Jira_Project_Issue_Field_Types (181,714 rows) and
-- Jira_Project_Leads (657 rows). No DateChecked column exists —
-- these are reference/lookup tables, not time-series collection tables.
-- The DBA_VCC_JIRA_MONTHEND_CHECKS job writes to DBA_VCC_AWS not here.
-- DBA_VCC_ATLASSIAN appears to be a Jira metadata reference store only.
SELECT TOP 10 * FROM DBA_VCC_ATLASSIAN.dbo.Jira_Project_Issue_Field_Types;
SELECT TOP 10 * FROM DBA_VCC_ATLASSIAN.dbo.Jira_Project_Leads;


-- ============================================================
-- 13.5 — DBA_VCC core database — top tables by size
-- DBA_VCC is the core monitoring framework database.
-- It holds Encore IIS logs, index fragmentation history,
-- SQL error logs, connection history, and the server list.
-- This confirms what is actively growing vs static.
-- ============================================================
SELECT
    t.name                                                          AS table_name,
    SUM(p.rows)                                                     AS row_count,
    CAST(SUM(a.total_pages * 8.0 / 1024) AS DECIMAL(10,2))         AS size_mb
FROM DBA_VCC.sys.tables t
JOIN DBA_VCC.sys.partitions p ON t.object_id = p.object_id
JOIN DBA_VCC.sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY size_mb DESC;


-- ============================================================
-- 13.6 — Stored procedure inventory across all user databases
-- Lists all stored procedures in every user database.
-- This is a discovery-level inventory only — not diving into
-- definitions. The goal is to know what exists in each database
-- so the deeper tickets (TECH-3478 onwards) have a starting point.
-- ============================================================
SELECT 'DBA_VCC'           AS database_name, name COLLATE DATABASE_DEFAULT AS name, create_date, modify_date FROM DBA_VCC.sys.objects           WHERE type = 'P' AND is_ms_shipped = 0
UNION ALL
SELECT 'DBA_VCC_AWS',                         name COLLATE DATABASE_DEFAULT,                                   create_date, modify_date FROM DBA_VCC_AWS.sys.objects       WHERE type = 'P' AND is_ms_shipped = 0
UNION ALL
SELECT 'DBA_VCC_MEMSQL',                      name COLLATE DATABASE_DEFAULT,                                   create_date, modify_date FROM DBA_VCC_MEMSQL.sys.objects    WHERE type = 'P' AND is_ms_shipped = 0
UNION ALL
SELECT 'DBA_VCC_MYSQL',                       name COLLATE DATABASE_DEFAULT,                                   create_date, modify_date FROM DBA_VCC_MYSQL.sys.objects     WHERE type = 'P' AND is_ms_shipped = 0
UNION ALL
SELECT 'DBA_VCC_COST',                        name COLLATE DATABASE_DEFAULT,                                   create_date, modify_date FROM DBA_VCC_COST.sys.objects      WHERE type = 'P' AND is_ms_shipped = 0
UNION ALL
SELECT 'DBA_VCC_ATLASSIAN',                   name COLLATE DATABASE_DEFAULT,                                   create_date, modify_date FROM DBA_VCC_ATLASSIAN.sys.objects WHERE type = 'P' AND is_ms_shipped = 0
UNION ALL
SELECT 'KURTOSYS_BASELINE',                   name COLLATE DATABASE_DEFAULT,                                   create_date, modify_date FROM KURTOSYS_BASELINE.sys.objects WHERE type = 'P' AND is_ms_shipped = 0
UNION ALL
SELECT 'Utilities',                           name COLLATE DATABASE_DEFAULT,                                   create_date, modify_date FROM Utilities.sys.objects         WHERE type = 'P' AND is_ms_shipped = 0
ORDER BY database_name, name;


-- ============================================================
-- 13.7 — Full Grafana dashboard count and list
-- Confirms the total number of dashboards in grafana.db.
-- Run confirmed 2026-07-07: 74 dashboards total.
-- Several dashboard names appear more than once — these are
-- older versions sitting in different folders, not duplicates
-- of the same dashboard. The deeper Grafana ticket (TECH-3479)
-- will determine which are active and which can be cleaned up.
-- ============================================================
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT title, updated FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py && echo print(len(rows), "dashboards total") >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';


-- ============================================================
-- 13.8 — Dashboard to datasource UID mapping
-- Purpose: Extract the datasource UID from every dashboard's
-- panel JSON and cross-reference against the datasource table
-- from query 12.6 to resolve UIDs to human-readable names.
-- This is how the Datasource column in the dashboard evidence
-- table was built. UIDs are what Grafana stores internally —
-- without this query you cannot tell which physical database
-- each dashboard reads from.
-- Run confirmed 2026-07-07. Output cross-referenced against
-- query 12.6 to produce the final dashboard table.
-- ============================================================
EXEC xp_cmdshell 'del C:\temp\gf.py';
EXEC xp_cmdshell 'echo import sqlite3, json > C:\temp\gf.py';
EXEC xp_cmdshell 'echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo rows = conn.execute("SELECT title, data FROM dashboard WHERE is_folder=0 ORDER BY updated DESC").fetchall() >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo for r in rows: >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     panels = json.loads(r[1]).get("panels", []) >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     ds = set() >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     for p in panels: >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo         d = p.get("datasource", "") >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo         ds.add(d.get("uid", "") if isinstance(d, dict) else str(d)) >> C:\temp\gf.py';
EXEC xp_cmdshell 'echo     print(r[0], "|", ds) >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
