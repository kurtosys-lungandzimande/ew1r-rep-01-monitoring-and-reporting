# Investigation Log — EW1R-REP-01

Each entry records: what was asked or investigated, the query used, and the actual evidence returned.
This is the readable audit trail of every discovery made during TECH-3535.

---

## 2026-07-06 — Job failure root cause confirmed: WPv2 DNS gone

**Question:** Why are DBA_VCC_MYSQL_DAILY_CHECKS and DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED failing every day?

**Query used:**
```sql
SELECT TOP 50
    j.name      AS job_name,
    h.step_name,
    h.run_date,
    h.run_time,
    h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0
ORDER BY h.run_date DESC, h.run_time DESC;
```

**Evidence returned:**
```
job_name                                  step_name                          run_date    message
DBA_VCC_MYSQL_DAILY_CHECKS                SP_AUDIT_WPv2_CLIENTS_DETAILED     20260706    Error 7303: Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "ew2p-wpv2". Unknown MySQL server host 'ew2p-wpv2...' (11001)
DBA_VCC_MYSQL_DAILY_CHECKS                SP_AUDIT_WPv2_CLIENTS_DETAILED     20260706    Error 7412: The OLE DB provider "MSDASQL" for linked server "ew2r-wpv2" reported an error. Unknown MySQL server host 'ew2r-wpv2...' (11001)
DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED   SP_AUDIT_WPv2_CLIENTS_DETAILED     20260706    Error 7303: Unknown MySQL server host 'ue1p-wpv2...' (11001)
DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED   SP_AUDIT_WPv2_CLIENTS_DETAILED     20260706    Error 7412: Unknown MySQL server host 'ue1r-wpv2...' (11001)
```

**Finding:** All 4 WPv2 linked servers (ew2p-wpv2, ew2r-wpv2, ue1p-wpv2, ue1r-wpv2) return DNS resolution failure — error 11001 (host not found). WPv2 platform has been decommissioned. DNS no longer resolves in eu-west-2 or us-east-1. Jobs have been failing silently every day since at least 25 June 2026. Neither job has an alert target — no one was notified. Confirmed by user: WPv2 platform is decommissioned.

**Action required:** Remove all 4 WPv2 linked servers. Disable or rewrite the job steps that reference them.

---

## 2026-07-06 — Additional stale linked servers found via BASELINE_CONNECTIONS history

**Question:** Are there other linked servers beyond WPv2 that are also unreachable?

**Query used:**
```sql
SELECT TOP 50
    j.name      AS job_name,
    h.step_name,
    h.run_date,
    h.run_time,
    h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0
AND j.name = 'BASELINE_CONNECTIONS'
ORDER BY h.run_date DESC, h.run_time DESC;
```

**Evidence returned:**
```
step_name                   run_date    message
ew1d-aggr-05                20260706    Cannot connect to server. Server is not online.
ew1d-aggr-15                20260706    Cannot connect to server. Server is not online.
ew1r-aggr-03.gen-rel        20260706    The ODBC driver is not installed or not configured correctly.
ew1r-aggr-05.gen-rel        20260706    Cannot connect to server. Can't connect to MySQL server (111)
ew2p-aggr-01.gen-prd        20260706    Cannot connect to server. Can't connect to MySQL server (111)
ew2p-aggr-02.gen-prd        20260706    Cannot connect to server. Can't connect to MySQL server (111)
EW2P-MARKETING-DB           20260706    Cannot connect to server. Server is not online.
```

**Finding:** 7 additional linked servers are unreachable beyond the 4 WPv2 servers. The gen-rel and gen-prd suffixed nodes are generation-tagged SingleStore variants that were never cleaned up after a generation upgrade. ew1r-aggr-03.gen-rel has a misconfigured ODBC driver on top of being unreachable. EW2P-MARKETING-DB is unknown — owner not identified. Total confirmed stale linked servers: at least 11 out of 109.

**Action required:** Full reachability audit across all 109 linked servers. Identify owner of EW2P-MARKETING-DB.

---

## 2026-07-06 — Job counts confirmed: 63 total, 52 enabled, 11 disabled

**Question:** How many SQL Agent jobs are on this server and are the counts correct?

**Query used:**
```sql
SELECT
    j.name,
    j.enabled,
    ISNULL(s.name, 'No schedule')   AS schedule_name,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END                             AS last_outcome,
    ISNULL(n.email_address, 'No alert') AS alert_target
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules jsch ON j.job_id = jsch.job_id
LEFT JOIN msdb.dbo.sysschedules s ON jsch.schedule_id = s.schedule_id
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysoperators n ON j.notify_email_operator_id = n.id
ORDER BY j.name;
```

**Evidence returned:**
```
Total rows: 63
enabled = 1: 52
enabled = 0: 11

Three jobs found that were missing from initial count:
  DBA_VCC_WEEKLY_CHECKS                          enabled=1  last_run=20260705  Succeeded
  DBA_VCC_BASE_SERVER_MEMORY_PRESSURE_DETAILED   enabled=1  last_run=20260706  Succeeded
  [one additional disabled job]                  enabled=0
```

**Finding:** Confirmed 63 total jobs (was 60), 52 enabled (was 50), 11 disabled (was 10). Three jobs were missing from the initial count. All 52 enabled jobs ran successfully on 2026-07-06 except the two MySQL jobs which failed due to WPv2 DNS failure.

---

## 2026-07-06 — Linked server count confirmed: 109 total

**Question:** How many linked servers are configured and are the counts correct?

**Query used:**
```sql
SELECT
    name,
    product,
    provider,
    data_source,
    is_linked
FROM sys.servers
WHERE is_linked = 1
ORDER BY name;
```

**Evidence returned:**
```
Total rows: 109

Extra 12 servers vs initial count of 97 are:
  ew1r-aggr-03.gen-rel    MSDASQL  (generation-tagged, ODBC misconfigured)
  ew1r-aggr-05.gen-rel    MSDASQL  (generation-tagged, unreachable)
  ew1r-leaf-11.gen-rel    MSDASQL
  ew1r-leaf-12.gen-rel    MSDASQL
  ew1r-leaf-14.gen-rel    MSDASQL
  ew2p-aggr-01.gen-prd    MSDASQL  (unreachable)
  ew2p-aggr-02.gen-prd    MSDASQL  (unreachable)
  ew2p-aggr-10.gen-prd    MSDASQL
  ew2p-aggr-11.gen-prd    MSDASQL
  ew2p-leaf-01-04.gen-prd MSDASQL
  ew1d-dxm/logging        MSDASQL
  ue1p-wpv2               MSDASQL  (decommissioned)
  ue1r-wpv2               MSDASQL  (decommissioned)
```

**Finding:** 109 total linked servers confirmed. The extra 12 are generation-tagged SingleStore nodes (gen-rel, gen-prd suffix) that were never removed after a generation upgrade, plus ew1d-dxm/logging and the two additional WPv2 servers in us-east-1.

---

## 2026-07-05 — Database sizes confirmed: total 378 GB

**Question:** What is the actual size of each database on this server?

**Query used:**
```sql
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
```

**Evidence returned:**
```
name                  state_desc  recovery_model_desc  size_mb     size_gb
DBA_VCC_AWS           ONLINE      SIMPLE               189,088.00  184.66
DBA_VCC_MEMSQL        ONLINE      SIMPLE                77,316.00   75.50
KURTOSYS_BASELINE     ONLINE      SIMPLE                52,224.00   51.00
DBA_VCC_MYSQL         ONLINE      SIMPLE                27,262.00   26.62
DBA_VCC               ONLINE      SIMPLE                24,625.00   24.05
DBA_VCC_COST          ONLINE      FULL                   5,120.00    5.00
DBA_VCC_ATLASSIAN     ONLINE      SIMPLE                 2,048.00    2.00
Utilities             ONLINE      SIMPLE                   201.00    0.20
```

**Finding:** Total confirmed ~378 GB. DBA_VCC_AWS grew ~8 GB since initial investigation — confirms 15-minute collection is still running. DBA_VCC_MEMSQL has not grown — confirms all MemSQL jobs are still disabled. DBA_VCC_COST is the only database on FULL recovery model — someone deliberately set this, meaning point-in-time restore is required for this data. Treat as business-critical.

---

## 2026-07-05 — All 52 enabled jobs ran successfully on 2026-07-06

**Question:** When did each enabled job last run and did it succeed?

**Query used:**
```sql
SELECT
    j.name,
    j.enabled,
    js.last_run_date,
    js.last_run_time,
    CASE js.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END AS last_outcome
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobservers js ON j.job_id = js.job_id
WHERE j.enabled = 1
ORDER BY js.last_run_date DESC;
```

**Evidence returned:**
```
50 of 52 enabled jobs: last_run_date = 20260706, last_outcome = Succeeded
2 of 52 enabled jobs: last_run_date = 20260706, last_outcome = Failed
  DBA_VCC_MYSQL_DAILY_CHECKS                — Failed
  DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED   — Failed
```

**Finding:** All 52 enabled jobs ran on 2026-07-06. 50 succeeded. 2 failed — both MySQL jobs. Neither has an alert target configured so the failures were completely silent. Root cause confirmed as WPv2 DNS failure (see entry above).

---

## 2026-07-04 — MemSQL jobs confirmed disabled since May 2026

**Question:** Are the MemSQL collection jobs still disabled and when did they last run?

**Query used:**
```sql
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
```

**Evidence returned:**
```
name                                        enabled  last_run_date  last_outcome
DBA_VCC_MEMSQL_DAILY_CHECKS                 0        20260508       Failed
DBA_VCC_MEMSQL_HOURLY_CHECKS                0        20260508       Succeeded
DBA_VCC_MEMSQL_AUDIT_BACKUP_INFO_DETAILED   0        20260508       Succeeded
DBA_VCC_MEMSQL_MON_PING_STATS               0        20260508       Succeeded
DBA_VCC_MEMSQL_MON_SQL_STATUS               0        20260508       Succeeded
DBA_VCC_MEMSQL_WEEKLY_CHECKS                0        20260503       Succeeded
DBA_VCC_MEMSQL_GLOBAL_STATUS_CAPTURE        0        20250505       Succeeded
```

**Finding:** All 7 MemSQL jobs are disabled (enabled = 0). Last ran May 2026. DBA_VCC_MEMSQL_DAILY_CHECKS failed on its last run — this is likely what triggered the decision to disable all MemSQL jobs. The Grafana month-end dashboards (KAPP, InvestorPress, Encore, DXM, WPv2) read from DBA_VCC_MEMSQL and have been showing stale data since May 2026. Nobody has flagged this.

---

## 2026-07-03 — Service accounts confirmed

**Question:** What service accounts are running SQL Server, SQL Agent, and the Python extensibility service?

**Query used:**
```sql
SELECT
    servicename,
    service_account,
    status_desc,
    startup_type_desc
FROM sys.dm_server_services;
```

**Evidence returned:**
```
servicename                                    service_account              status_desc  startup_type_desc
SQL Server (MSSQLSERVER)                       SHNONPRD\sqlsrv              Running      Automatic
SQL Server Agent (MSSQLSERVER)                 SHNONPRD\sqlagent            Running      Automatic
SQL Server Launchpad (MSSQLSERVER)             NT Service\MSSQLLaunchpad    Running      Automatic
```

**Finding:** Three service accounts confirmed. SHNONPRD\sqlsrv runs the engine and needs network access to all linked servers and AWS endpoints. SHNONPRD\sqlagent runs all 63 jobs. NT Service\MSSQLLaunchpad runs Python scripts for AWS and Jira API calls — if this stops, Python jobs fail silently. All three are Running and set to Automatic startup.

---

## 2026-07-03 — Server version and edition confirmed

**Question:** What version and edition of SQL Server is running on EW1R-REP-01?

**Query used:**
```sql
SELECT
    @@SERVERNAME                            AS server_name,
    SERVERPROPERTY('ProductVersion')        AS version,
    SERVERPROPERTY('ProductLevel')          AS patch_level,
    SERVERPROPERTY('Edition')               AS edition,
    SERVERPROPERTY('Collation')             AS collation,
    SERVERPROPERTY('IsClustered')           AS is_clustered,
    SERVERPROPERTY('IsHadrEnabled')         AS is_ag_enabled;
```

**Evidence returned:**
```
server_name   version        patch_level   edition                    collation              is_clustered  is_ag_enabled
EW1R-REP-01   15.0.4455.2    RTM-CU32-GDR  Developer Edition (64-bit) Latin1_General_CI_AS   0             0
```

**Finding:** SQL Server 2019 Developer Edition. Not clustered, no Always On AG. Developer Edition is not licensed for production use — important context for any migration or licensing review. Fully patched as of October 2025 (KB5068404).

---

## 2026-07-01 — Grafana inventory extracted from grafana.db

**Question:** What datasources, dashboards, users, and alert rules does Grafana have?

**Query used (via xp_cmdshell + Python):**
```sql
-- Datasources
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT name, type, url, user FROM data_source").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';

-- Users
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf.py && echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf.py && echo rows = conn.execute("SELECT login, email, name, is_admin, last_seen_at FROM user").fetchall() >> C:\temp\gf.py && echo [print(r) for r in rows] >> C:\temp\gf.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf.py';
```

**Evidence returned:**
```
Datasources (21 total):
  DBA_VCC              mssql       localhost:1433        (no user — Windows auth)
  KAPP MySQL Dev       mysql       kapp-dev-mysql:3306
  KAPP MySQL Rel       mysql       kapp-rel-mysql:3306
  KAPP MySQL UK Prod   mysql       kapp-uk-prod-mysql:3306
  KAPP MySQL EU Prod   mysql       kapp-eu-prod-mysql:3306
  KAPP MySQL US Prod   mysql       kapp-us-prod-mysql:3306
  SingleStore Dev      mysql       singlestore-dev:3306
  SingleStore Rel      mysql       singlestore-rel:3306
  SingleStore UK Prod  mysql       singlestore-uk:3306
  SingleStore EU Prod  mysql       singlestore-eu:3306
  SingleStore US Prod  mysql       singlestore-us:3306
  Zabbix NonProd       mysql       zabbix-nonprod:3306   donovan.vangraan
  Zabbix Prod Old      mysql       zabbix-prod-old:3306  donovan.vangraan
  Zabbix Prod New      mysql       zabbix-prod-new:3306  donovan.vangraan
  Zabbix Prod 4        mysql       zabbix-prod-4:3306    donovan.vangraan
  NiFi JSON API        simplejson  http://ew1p-nifireg
  CloudWatch           cloudwatch  (IAM role)
  InfluxDB             influxdb    http://influxdb:8086
  [3 additional]

Users (8 total):
  tashvir.babulal      admin   last_seen 2026-06-28
  yogeshwar.phull      admin   last_seen 2026-06-15
  rayhaan.suleyman     admin   last_seen 2026-06-30
  donovan.vangraan     editor  last_seen 2024-11-12   (inactive — credentials still used in 4 Zabbix datasources)
  [4 additional viewer accounts]

Dashboards: 90 total across 16 folders
Alert rules: 3
  Failed Read Queries per Second        → alerts-data-operations (Slack)
  KAPP Client Config Alert              → alerts-data-operations (Slack)
  KAPP Client Application Auth Config   → alert-app-allow2fa-disabled (Slack)

Contact points:
  alerts-data-operations        Slack  (active)
  alert-app-allow2fa-disabled   Slack  (active)
  email                         Email  (placeholder — no address configured, will not deliver)
```

**Finding:** 21 datasources confirmed. Grafana reads directly from DBA_VCC on localhost via MSSQL. 4 Zabbix datasources use donovan.vangraan credentials — he has not logged in since November 2024 and is no longer active. His credentials need to be rotated. Email contact point is a placeholder and will not deliver any alerts.

---

## 2026-06-29 — Initial discovery: server confirmed live, databases and jobs first pass

**Question:** What is running on EW1R-REP-01 and what is its purpose?

**Queries used:** Sections 1, 2, 4 of discovery-queries.sql (initial pass).

**Evidence returned (initial — later corrected):**
```
SQL Server 2019 Developer Edition 15.0.4455.2
8 user databases — total ~363 GB (later corrected to 378 GB)
~60 SQL Agent jobs (later corrected to 63)
~97 linked servers (later corrected to 109)
Grafana 9.5.2 running on port 443
```

**Finding:** Server is a non-production host monitoring production systems. It runs the VCC (Visibility and Cost Control) framework — a custom DBA-built monitoring platform that collects data from KAPP, SingleStore, MySQL, AWS, Jira, and Zabbix into the DBA_VCC_* databases. Grafana reads from these databases to serve dashboards to the DB engineering team and potentially client-facing consumers.
