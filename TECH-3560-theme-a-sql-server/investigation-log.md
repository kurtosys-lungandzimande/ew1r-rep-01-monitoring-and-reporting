# TECH-3478 — Theme A: SQL Server — Investigation Log

Scope: SQL Server inventory — databases, jobs, linked servers, service accounts, data freshness.
Each entry has the question, the query, the evidence, and the finding.

---

## 2026-07-06 — AWS cost ETL silently failing since Sept 2024 — 2.4M rows stuck in staging

**Question:** Is AWS cost data still being collected and why is INFO_AWS_DE_Entity_Cost stale?

**Query 1 — Last collected date per cost table:**
```sql
SELECT
    'DBA_VCC_AWS - INFO_AWS_Entity_Cost'    AS table_name,
    MAX(DateChecked)                        AS last_collected,
    COUNT(*)                                AS total_rows
FROM DBA_VCC_AWS.dbo.INFO_AWS_Entity_Cost
UNION ALL
SELECT
    'DBA_VCC_COST - INFO_AWS_DE_Entity_Cost',
    MAX(DateChecked),
    COUNT(*)
FROM DBA_VCC_COST.dbo.INFO_AWS_DE_Entity_Cost;
```

**Evidence:**
```
DBA_VCC_AWS  - INFO_AWS_Entity_Cost      2024-09-22 06:02:28   60,045 rows
DBA_VCC_COST - INFO_AWS_DE_Entity_Cost   2024-12-05 12:56:42    4,382 rows
```

**Query 2 — Daily job steps — is the cost collection step still present:**
```sql
SELECT j.name, j.enabled, s.step_id, s.step_name, s.command
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
WHERE j.name = 'DBA_VCC_AWS_DAILY_CHECKS'
ORDER BY s.step_id;
```

**Evidence:**
```
Step 1  SP_AUDIT_AWS_PY_CALL_DETAILED 'bucketsizes'           enabled
Step 2  SP_AUDIT_S3_ETL_CLEANUP                               enabled
Step 3  SP_AUDIT_AWS_PY_CALL_DETAILED 'costs'                 enabled
Step 4  SP_AUDIT_COST_ETL_CLEANUP                             enabled
Step 5  SP_AUDIT_AWS_PY_CALL_DETAILED 'region_data_transfer'  enabled
Step 6  SP_AUDIT_DATATRANSFER_REGIONAL_BYTES_ETL_CLEANUP      enabled
```

**Query 3 — Last 5 runs of the daily job:**
```sql
SELECT TOP 5 j.name, h.run_date, h.run_time,
    CASE h.run_status WHEN 0 THEN 'Failed' WHEN 1 THEN 'Succeeded' ELSE 'Other' END AS status
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE j.name = 'DBA_VCC_AWS_DAILY_CHECKS' AND h.step_id = 0
ORDER BY h.run_date DESC, h.run_time DESC;
```

**Evidence:**
```
DBA_VCC_AWS_DAILY_CHECKS  20260706  060000  Succeeded
DBA_VCC_AWS_DAILY_CHECKS  20260705  060000  Succeeded
DBA_VCC_AWS_DAILY_CHECKS  20260704  060000  Succeeded
DBA_VCC_AWS_DAILY_CHECKS  20260703  060000  Succeeded
DBA_VCC_AWS_DAILY_CHECKS  20260702  060000  Succeeded
```

**Query 4 — Staging table row count:**
```sql
SELECT COUNT(*) AS row_count FROM DBA_VCC_AWS.dbo.MON_AWS_Entity_Cost;
```

**Evidence:**
```
2,478,382 rows
```

**Query 5 — Staging table columns:**
```sql
SELECT column_name, data_type
FROM DBA_VCC_AWS.information_schema.columns
WHERE table_name = 'MON_AWS_Entity_Cost'
ORDER BY ordinal_position;
```

**Evidence:**
```
AccountId     nvarchar
EntityName    nvarchar
Cost          nvarchar
Unit          nvarchar
EstimatedCost nvarchar
Period        nvarchar
```

**Query 6 — What does SP_AUDIT_COST_ETL_CLEANUP do:**
```sql
SELECT o.name, m.definition
FROM DBA_VCC_AWS.sys.sql_modules m
JOIN DBA_VCC_AWS.sys.objects o ON m.object_id = o.object_id
WHERE o.name = 'SP_AUDIT_COST_ETL_CLEANUP';
```

**Evidence (key section):**
```sql
MERGE [DBA_VCC_AWS].[dbo].[INFO_AWS_Entity_Cost] WITH (HOLDLOCK) AS Target
USING (SELECT DISTINCT [AccountId],[EntityName],[Cost],[Unit],[EstimatedCost],[Period]
       FROM [DBA_VCC_AWS].[dbo].[MON_AWS_Entity_Cost]) AS Source
ON (Target.[AccountId]=Source.[AccountId] AND Target.[EntityName]=Source.[EntityName]
    AND Target.[Period]=Source.[Period])
WHEN NOT MATCHED BY TARGET THEN
    INSERT (...) VALUES (..., convert(decimal(20,10),Source.[Cost]), ...);
-- Cost is nvarchar — convert fails if any row has non-numeric value
TRUNCATE TABLE [DBA_VCC_AWS].[dbo].[MON_AWS_Entity_Cost]; -- never runs if MERGE fails
```

**Finding:** The Python `costs` call works — 2.4M rows are landing in staging. The problem is SP_AUDIT_COST_ETL_CLEANUP does `convert(decimal(20,10), Cost)` but Cost is nvarchar. One bad row causes the entire MERGE to roll back. The CATCH block swallows the error — job reports Succeeded, nobody is notified, TRUNCATE never runs, staging keeps growing since September 2024. Two cost tables affected via separate paths. Discovery finding only — raise as separate ticket to fix.

---

## 2026-07-06 — DBA_VCC_AWS_15MIN_CHECKS: MERGE taking 9+ min on 563M row table

**Question:** Is the 30-min KAPP collection job still running on schedule?

**Query 1 — Last 10 runs:**
```sql
SELECT TOP 10 j.name, h.run_date, h.run_time,
    CASE h.run_status WHEN 0 THEN 'Failed' WHEN 1 THEN 'Succeeded' ELSE 'Other' END AS status
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE j.name = 'DBA_VCC_AWS_15MIN_CHECKS' AND h.step_id = 0
ORDER BY h.run_date DESC, h.run_time DESC;
```

**Evidence:**
```
20260706  130000  Succeeded
20260706  123000  Succeeded
20260706  120000  Succeeded
20260706  113000  Succeeded
20260706  110000  Succeeded
20260706  103000  Succeeded
20260706  100000  Succeeded
20260706  93000   Succeeded
20260706  90000   Succeeded
20260706  83000   Succeeded
```

**Query 2 — Is it currently running:**
```sql
SELECT j.name, a.start_execution_date, a.stop_execution_date,
       a.last_executed_step_id, a.last_executed_step_date
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobactivity a ON j.job_id = a.job_id
WHERE j.name = 'DBA_VCC_AWS_15MIN_CHECKS'
AND a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity);
```

**Evidence:**
```
start=2026-07-06 13:30:00  stop=NULL  last_step=3  last_step_date=2026-07-06 13:30:11
```

**Query 3 — MERGE progress on active session:**
```sql
SELECT r.session_id, r.command, r.status, r.percent_complete,
       r.cpu_time/1000 AS cpu_seconds, r.total_elapsed_time/1000 AS elapsed_seconds,
       r.reads, r.writes, r.logical_reads
FROM sys.dm_exec_requests r WHERE r.session_id = 67;
```

**Evidence:**
```
session_id=67  MERGE  running  percent_complete=0  cpu=531s  elapsed=534s  reads=3,461,771  writes=1
```

**Finding:** Job is healthy and running every 30 minutes (schedule is :00 and :30, not every 15 min as originally noted). The MERGE into INFO_AWS_KAPP_Query_API_Detail (563M rows, no partitioning) is already taking 9+ minutes per run. No blocking. As the table grows this will eventually exceed 30 minutes and runs will overlap. Written by donovan.vangraan (Feb 2024) who is no longer active. This is a performance risk for RDS migration — needs redesign before moving.

---

## 2026-07-06 — WPv2 linked servers dead — 2 jobs failing silently since 25 June 2026

**Question:** Why are DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing?

**Query:**
```sql
SELECT TOP 50 j.name AS job_name, h.step_name, h.run_date, h.run_time, h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0
ORDER BY h.run_date DESC, h.run_time DESC;
```

**Evidence:**
```
DBA_VCC_MYSQL_DAILY_CHECKS               SP_AUDIT_WPv2_CLIENTS_DETAILED  20260706  Error 7303: Unknown MySQL server host 'ew2p-wpv2' (11001)
DBA_VCC_MYSQL_DAILY_CHECKS               SP_AUDIT_WPv2_CLIENTS_DETAILED  20260706  Error 7412: Unknown MySQL server host 'ew2r-wpv2' (11001)
DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED  SP_AUDIT_WPv2_CLIENTS_DETAILED  20260706  Error 7303: Unknown MySQL server host 'ue1p-wpv2' (11001)
DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED  SP_AUDIT_WPv2_CLIENTS_DETAILED  20260706  Error 7412: Unknown MySQL server host 'ue1r-wpv2' (11001)
```

**Finding:** All 4 WPv2 linked servers return DNS error 11001 — host not found. WPv2 platform confirmed decommissioned. Failing silently every day since 25 June 2026. Neither job has an alert target — nobody was notified. Action required: remove all 4 linked servers and clean up referencing job steps.

---

## 2026-07-06 — Additional stale linked servers beyond WPv2

**Question:** Are there other unreachable linked servers beyond WPv2?

**Query:**
```sql
SELECT TOP 50 j.name, h.step_name, h.run_date, h.run_time, h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0 AND j.name = 'BASELINE_CONNECTIONS'
ORDER BY h.run_date DESC, h.run_time DESC;
```

**Evidence:**
```
ew1d-aggr-05          20260706  Cannot connect. Server is not online.
ew1d-aggr-15          20260706  Cannot connect. Server is not online.
ew1r-aggr-03.gen-rel  20260706  ODBC driver not installed or not configured correctly.
ew1r-aggr-05.gen-rel  20260706  Can't connect to MySQL server (111)
ew2p-aggr-01.gen-prd  20260706  Can't connect to MySQL server (111)
ew2p-aggr-02.gen-prd  20260706  Can't connect to MySQL server (111)
EW2P-MARKETING-DB     20260706  Cannot connect. Server is not online.
```

**Finding:** 7 additional stale linked servers confirmed. gen-rel and gen-prd nodes are generation-tagged SingleStore variants never cleaned up after a generation upgrade. ew1r-aggr-03.gen-rel also has a misconfigured ODBC driver. EW2P-MARKETING-DB owner unknown. Total confirmed stale: 11 out of 109. Full reachability audit needed.

---

## 2026-07-06 — Job counts confirmed: 63 total, 52 enabled, 11 disabled

**Query:**
```sql
SELECT j.name, j.enabled, ISNULL(s.name,'No schedule') AS schedule,
    js.last_run_date, js.last_run_time,
    CASE js.last_run_outcome WHEN 0 THEN 'Failed' WHEN 1 THEN 'Succeeded' ELSE 'Unknown' END AS last_outcome,
    ISNULL(n.email_address,'No alert') AS alert_target
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules jsch ON j.job_id = jsch.job_id
LEFT JOIN msdb.dbo.sysschedules s ON jsch.schedule_id = s.schedule_id
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysoperators n ON j.notify_email_operator_id = n.id
ORDER BY j.name;
```

**Evidence:**
```
Total: 63  Enabled: 52  Disabled: 11
50 of 52 enabled jobs — last_run=20260706  Succeeded
2 of 52 enabled jobs  — last_run=20260706  Failed (both MySQL jobs — WPv2 DNS failure)
```

**Finding:** Confirmed 63 jobs (was 60), 52 enabled (was 50), 11 disabled (was 10). Three jobs were missing from initial count. All failures are silent — no alert target on the two failing MySQL jobs.

---

## 2026-07-06 — Linked server count confirmed: 109 total

**Query:**
```sql
SELECT name, product, provider, data_source FROM sys.servers WHERE is_linked = 1 ORDER BY name;
```

**Evidence:**
```
Total: 109
Extra 12 vs initial count of 97:
  ew1r-aggr-03.gen-rel, ew1r-aggr-05.gen-rel, ew1r-leaf-11/12/14.gen-rel
  ew2p-aggr-01/02/10/11.gen-prd, ew2p-leaf-01-04.gen-prd
  ew1d-dxm/logging, ue1p-wpv2, ue1r-wpv2
```

**Finding:** 109 confirmed. Extra 12 are generation-tagged SingleStore nodes never removed after a generation upgrade, plus 2 additional WPv2 servers in us-east-1.

---

## 2026-07-05 — Database sizes confirmed: 378 GB total

**Query:**
```sql
SELECT d.name, d.state_desc, d.recovery_model_desc,
    CAST(SUM(f.size * 8.0 / 1024) AS DECIMAL(10,2)) AS size_mb,
    CAST(SUM(f.size * 8.0 / 1024 / 1024) AS DECIMAL(10,2)) AS size_gb
FROM sys.databases d
JOIN sys.master_files f ON d.database_id = f.database_id
GROUP BY d.name, d.state_desc, d.recovery_model_desc
ORDER BY size_mb DESC;
```

**Evidence:**
```
DBA_VCC_AWS        189,088 MB  184.66 GB  SIMPLE  — actively growing
DBA_VCC_MEMSQL      77,316 MB   75.50 GB  SIMPLE  — static, jobs disabled
KURTOSYS_BASELINE   52,224 MB   51.00 GB  SIMPLE
DBA_VCC_MYSQL       27,262 MB   26.62 GB  SIMPLE
DBA_VCC             24,625 MB   24.05 GB  SIMPLE  — actively growing
DBA_VCC_COST         5,120 MB    5.00 GB  FULL    — only FULL recovery on server
DBA_VCC_ATLASSIAN    2,048 MB    2.00 GB  SIMPLE
Utilities              201 MB    0.20 GB  SIMPLE
```

**Finding:** Total 378 GB. DBA_VCC_AWS grew ~8 GB since investigation started — collection pipeline healthy. DBA_VCC_MEMSQL static — all jobs disabled. DBA_VCC_COST is the only FULL recovery database — treat as business-critical, point-in-time restore required.

---

## 2026-07-04 — MemSQL jobs all disabled since May 2026

**Query:**
```sql
SELECT j.name, j.enabled, js.last_run_date,
    CASE js.last_run_outcome WHEN 0 THEN 'Failed' WHEN 1 THEN 'Succeeded' ELSE 'Unknown' END AS last_outcome
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.name LIKE '%MEMSQL%'
ORDER BY js.last_run_date DESC;
```

**Evidence:**
```
DBA_VCC_MEMSQL_DAILY_CHECKS              enabled=0  last_run=20260508  Failed
DBA_VCC_MEMSQL_HOURLY_CHECKS             enabled=0  last_run=20260508  Succeeded
DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED enabled=0 last_run=20260508  Succeeded
DBA_VCC_MEMSQL_MON_PING_STATS            enabled=0  last_run=20260508  Succeeded
DBA_VCC_MEMSQL_MON_SQL_STATUS            enabled=0  last_run=20260508  Succeeded
DBA_VCC_MEMSQL_WEEKLY_CHECKS             enabled=0  last_run=20260503  Succeeded
DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE     enabled=0  last_run=20250505  Succeeded
```

**Finding:** All 7 MemSQL jobs disabled. Last ran May 2026. DAILY_CHECKS failed on last run — likely triggered the decision to disable all. Grafana month-end dashboards read from DBA_VCC_MEMSQL — they have been showing stale data since May 2026. Nobody has flagged this.
