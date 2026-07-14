# TECH-3535 — Planning & Discovery — Investigation Log

Scope: Initial discovery on EW1R-REP-01 — what is running, what depends on it, what risks exist before decommission.
Each entry has the question, the query, the evidence, and the finding.

> Status: Discovery complete. All 5 scope items done. Open questions documented in open-questions.md. Topology and classification in progress — TECH-3481.

---

## 2026-07-07 — 14 Grafana dashboards showing stale data since May 2026 — nobody noticed

**Question:** Which dashboards are affected by the DBA_VCC_MEMSQL jobs being disabled?

**Query — scan all dashboard JSON for DBA_VCC_MEMSQL references (query 12.5):**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_memsql.py';
EXEC xp_cmdshell 'echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_memsql.py';
EXEC xp_cmdshell 'echo rows = conn.execute("SELECT title, updated FROM dashboard WHERE is_folder=0 AND data LIKE ''%DBA_VCC_MEMSQL%'' ORDER BY updated DESC").fetchall() >> C:\temp\gf_memsql.py';
EXEC xp_cmdshell 'echo [print(r) for r in rows] >> C:\temp\gf_memsql.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_memsql.py';
```

**Evidence:**
```
KAPP Dataset Query and Source Execution    2024-11-20
KAPP Dataset Query Execution               2024-11-07
KAPP Client Application Auth Config        2024-10-29
KAPP Dataset Lambdas Time Outs             2024-10-23
KAPP Client Config                         2024-09-02
KAPP Workflow Times History                2024-06-12
KAPP Orphaned and Duplicated Records Report 2024-03-26
KAPP API Error Reporting                   2024-03-11
Query Performance Dashboard                2024-03-07
KAPP Workflow History                      2024-03-07
KAPP Client Growth                         2024-02-28
Nifi API Reporting Copy                    2023-09-21
InvestorPress Month End Reporting          2023-08-10
KAPP Month End Reporting                   2023-08-10
```

**Finding:** 14 dashboards confirmed reading from DBA_VCC_MEMSQL. All 7 MemSQL collection jobs were disabled in May 2026 — these dashboards have been showing stale data ever since. No alert fired. No one raised an incident. Confirm with yogeshwar.phull and tashvir.babulal whether the jobs were intentionally disabled and whether these dashboards are still expected to show live data.

---

## 2026-07-07 — 6 month-end dashboards have no dedicated jobs and depend on the broken MEMSQL feed

**Question:** Do the month-end dashboards have their own data pipeline or do they depend on the MEMSQL feed?

**Query 1 — scan all dashboard JSON for REP_MONTHEND references (query 12.4):**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_monthend.py';
EXEC xp_cmdshell 'echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_monthend.py';
EXEC xp_cmdshell 'echo rows = conn.execute("SELECT title, updated FROM dashboard WHERE is_folder=0 AND data LIKE ''%REP_MONTHEND%'' ORDER BY updated DESC").fetchall() >> C:\temp\gf_monthend.py';
EXEC xp_cmdshell 'echo [print(r) for r in rows] >> C:\temp\gf_monthend.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_monthend.py';
```

**Query 2 — check for dedicated month-end SQL Agent jobs:**
```sql
SELECT j.name, j.enabled,
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS last_run,
    h.run_status, h.message
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id AND h.step_id = 0
WHERE j.name LIKE '%MONTHEND%' OR j.name LIKE '%month_end%'
ORDER BY h.run_date DESC;
```

**Evidence:**
```
Dashboards calling REP_MONTHEND procedures:
WPv2 Month End Reporting                    2024-06-20  no dedicated job — reads DBA_VCC_MEMSQL directly
Encore Month End Reporting                  2023-08-10  no dedicated job — reads DBA_VCC_MEMSQL directly
DXM Month End Reporting                     2023-08-10  no dedicated job — reads DBA_VCC_MEMSQL directly
InvestorPress Month End Reporting           2023-08-10  no dedicated job — reads DBA_VCC_MEMSQL directly
KAPP Month End Reporting                    2023-08-10  no dedicated job — reads DBA_VCC_MEMSQL directly
Other Services Month End Reporting (Draft)  2023-07-21  no dedicated job — reads DBA_VCC_MEMSQL directly

Jobs matching MONTHEND:
DBA_VCC_JIRA_MONTHEND_CHECKS  enabled  last_run=2026-07-01 08:00  Succeeded
-- only one job returned — no jobs for WPv2/Encore/DXM/InvestorPress/KAPP
```

**Finding:** 6 month-end dashboards call REP_MONTHEND stored procedures with no independent data pipeline. They read directly from DBA_VCC_MEMSQL tables — the same tables with no new data since May 2026. June 2026 month-end reporting was impacted. No error shown in Grafana — dashboards silently display stale data. Resolving this requires re-enabling the MEMSQL feed jobs. Disclose to whoever uses these reports.

---

## 2026-07-07 — DBA_VCC_COST confirmed active Grafana datasource — KAPP Client Utilisation may be client-facing

**Question:** Which dashboards read from DBA_VCC_COST and is any of them client-facing?

**Query — scan all dashboard JSON for DBA_VCC_COST references (query 12.3):**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_cost.py';
EXEC xp_cmdshell 'echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_cost.py';
EXEC xp_cmdshell 'echo rows = conn.execute("SELECT title, updated FROM dashboard WHERE is_folder=0 AND data LIKE ''%DBA_VCC_COST%'' ORDER BY updated DESC").fetchall() >> C:\temp\gf_cost.py';
EXEC xp_cmdshell 'echo [print(r) for r in rows] >> C:\temp\gf_cost.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_cost.py';
```

**Evidence:**
```
Database Engineering Costs                  2024-10-15  internal
Database Engineering Sprint Reporting       2024-03-08  internal
KAPP Client Utilisation and Growth Report   2024-02-22  ⚠️ name suggests client-facing
AWS Cost Report Monthly                     2023-10-06  internal — AWS data stale since Sept 2024
```

**Finding:** 4 dashboards confirmed reading from DBA_VCC_COST. DBA_VCC_COST is on FULL recovery — the only database on this server deliberately set that way. Collection job last succeeded 29 June 2026. `KAPP Client Utilisation and Growth Report` is the highest risk — name strongly suggests client-facing use. Must confirm with tashvir.babulal and rayhaan.suleyman before any decommission date is set.

---

## 2026-07-07 — Grafana datasource UID mapping — duplicate DBA_VCC entries confirmed

**Question:** What UIDs do Grafana datasources use — needed to map dashboard JSON references to datasource names.

**Query (query 12.6):**
```sql
EXEC xp_cmdshell 'echo import sqlite3 > C:\temp\gf_ds_uid.py';
EXEC xp_cmdshell 'echo conn = sqlite3.connect(r"C:\Program Files\GrafanaLabs\grafana\data\grafana.db") >> C:\temp\gf_ds_uid.py';
EXEC xp_cmdshell 'echo rows = conn.execute("SELECT uid, name, type, url, json_data FROM data_source ORDER BY name").fetchall() >> C:\temp\gf_ds_uid.py';
EXEC xp_cmdshell 'echo [print(r) for r in rows] >> C:\temp\gf_ds_uid.py';
EXEC xp_cmdshell 'C:\Users\sqlsrv\AppData\Local\Programs\Python\Python311\python.exe C:\temp\gf_ds_uid.py';
```

**Evidence:**
```
a082f27e  DBA_VCC   mssql  localhost  — core SQL Server datasource
e8597015  DBA_VCC   mssql  localhost  — ⚠️ duplicate entry, same datasource registered twice
```

**Finding:** DBA_VCC has two entries with different UIDs both pointing to localhost. Dashboards are split across both UIDs. Must be resolved before any migration — dashboards referencing the removed UID will break. Full datasource list in TECH-3561 investigation-log.md.

---

## 2026-07-06 — Scope confirmed: 5 items, all done except topology

**Question:** What is the full scope of TECH-3535 and what is still outstanding?

**Evidence:**
```
1  Run SQL discovery queries and capture outputs       Done  — 13 sections, all outputs in discovery-queries.sql
2  Inventory SQL Server and Grafana components         Done  — TECH-3560 (SQL Server), TECH-3561 (Grafana)
3  Map external targets and consumers                  Done  — TECH-3562
4  Document open questions and blockers                Done  — 34 questions in open-questions.md
5  Produce topology and risk classification            In Progress  — TECH-3481, blocked on stakeholder answers
```

**Finding:** Discovery complete. Topology blocked on consumer confirmation questions — who uses DBA_VCC_COST for billing, is KAPP Client Utilisation client-facing, who calls REP_MONTHEND procedures. Escalated to tashvir.babulal and rayhaan.suleyman.

---

## 2026-07-06 — Risks identified at discovery level

**Question:** What are the key risks before decommission work begins?

**Evidence:**
```
WPv2 linked servers dead — 2 jobs failing silently daily since 25 Jun 2026          Critical
Additional stale linked servers beyond WPv2 — 11 confirmed out of 109               Critical
Client-facing dashboard exposure not confirmed                                       Critical
VCC framework not replicated — single point of failure                               High
Silent ETL failures — CATCH blocks swallow errors, jobs report Succeeded             High
AWS cost data stale since Sept 2024 — no alert, no one noticed                       High
MERGE on 563M row unpartitioned table approaching schedule interval                  High
No runbook or documentation exists for this server                                   Medium
Developer Edition not licensed for production use                                    Medium
```

**Finding:** 3 critical risks must be resolved before decommission date is set. Full detail per risk in the relevant theme ticket. Topology and classification in TECH-3481.

---

## Links

| Resource | Location |
|---|---|
| Discovery queries | TECH-3535-planning-and-discovery/discovery-queries.sql |
| Open questions | TECH-3535-planning-and-discovery/open-questions.md |
| Architecture diagram | TECH-3535-planning-and-discovery/ew1r-rep-01-architecture.drawio |
| SQL Server detail | TECH-3560-theme-a-sql-server/investigation-log.md |
| Grafana detail | TECH-3561-theme-b-grafana/investigation-log.md |
| Targets & consumers detail | TECH-3562-theme-c-targets-and-consumers/investigation-log.md |
| Topology & classification | TECH-3481-theme-d-classification-and-topology/investigation-log.md |
