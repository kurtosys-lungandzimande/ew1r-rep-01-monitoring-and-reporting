# TECH-3535 — Planning & Discovery

---

## Summary

Perform initial investigation and discovery on EW1R-REP-01 to understand what is running, what depends on it, and what risks exist before any decommission work begins.

EW1R-REP-01 is a non-production Windows host running SQL Server 2019 and Grafana 9.5.2. It hosts the VCC (Visibility and Cost Control) framework — a custom DBA-built monitoring platform that collects data from KAPP, SingleStore, MySQL, AWS, Jira, and Zabbix. Production does not run on this server but production visibility depends on it. It is the only known instance of the VCC framework.

---

## Scope

| # | Scope Item | Status | Owner Ticket |
|---|---|---|---|
| 1 | Run SQL discovery queries and capture outputs | ✅ Done | TECH-3535 |
| 2 | Inventory SQL Server and Grafana components | ✅ Done | TECH-3478 / TECH-3479 |
| 3 | Map external targets and consumers | 🔄 In Progress | TECH-3480 |
| 4 | Document open questions and blockers | ✅ Done | TECH-3535 |
| 5 | Produce a topology and risk classification | ⏳ Blocked | TECH-3481 |

---

## Definition of Done — Progress

| DoD Item | Status | Notes |
|---|---|---|
| All discovery queries executed and outputs captured | ✅ Done | 13 sections of discovery queries run — captured in discovery-queries.sql |
| SQL Server inventory complete (jobs, databases, linked servers) | ✅ Done | Jobs, databases, 109 linked servers inventoried — TECH-3478 owns the detail |
| Grafana inventory complete (datasources, dashboards, users, alerts) | ✅ Done | 21 datasources, dashboards, 3 active users, 2 alert channels captured — TECH-3479 owns the detail |
| External targets and consumers mapped | 🔄 In Progress | Data sources identified — consumer confirmation still open, TECH-3480 owns this |
| Open questions documented and blockers escalated | ✅ Done | 34 open questions logged in open-questions.md — critical blockers flagged |
| Topology and classification published to Confluence | ⏳ Blocked | Blocked on TECH-3478, TECH-3479, TECH-3480 completing — TECH-3481 owns this |

---

## What we found — by scope item

### 1. Discovery queries

Initial discovery queries executed across 13 sections covering server basics, databases, jobs, linked servers, Grafana, AWS cost data, job-to-linked-server mapping, and database/stored proc coverage across all 8 databases. All outputs captured in discovery-queries.sql.

---

### 2. SQL Server inventory

- SQL Server 2019 Developer Edition — not clustered, no AG
- Three service accounts: SQL Server engine, SQL Agent, Launchpad (Python-based API jobs)
- SQL Agent jobs running on schedules from every 15 minutes to daily
- 109 linked servers connecting to SingleStore, MySQL, and RDS targets
- Several linked servers confirmed unreachable — WPv2 platform decommissioned, 4 linked servers dead
- Additional stale targets identified beyond WPv2
- At least two ETL jobs have silent failures — CATCH blocks swallow errors, jobs report Succeeded

→ Full detail in TECH-3478

### 2b. Grafana inventory

- Grafana 9.5.2 on port 443 (HTTPS)
- 21 datasources: SQL Server (localhost), KAPP MySQL, SingleStore, Zabbix MySQL, NiFi, CloudWatch, InfluxDB
- 3 active admin users, 1 inactive builder (no longer active)
- 2 Slack alert channels configured — email contact point is a placeholder, not configured
- Some dashboards are candidates for client-facing or SLA use — not yet confirmed

→ Full detail in TECH-3479

---

### 3. External targets and consumers

Data sources feeding into EW1R-REP-01: KAPP, SingleStore, MySQL, AWS, Jira, Zabbix.

- Not all targets are reachable — WPv2 confirmed decommissioned, others suspected stale
- Consumers: DB engineering confirmed. Client-facing unconfirmed
- AWS cost data stale since September 2024 — no consumer noticed, raises questions about active use

→ Full detail in TECH-3480

---

### 4. Open questions and blockers

34 open questions documented. Critical blockers escalated:

- WPv2 decommission cleanup — no owner assigned, jobs failing silently daily
- Client-facing dashboard exposure — not confirmed, needs stakeholder input
- Consumer confirmation for AWS cost and KAPP data — needed before any decommission decision

→ Full list in open-questions.md

---

### 5. Topology and risk classification

Not started. Blocked on Themes A, B, and C completing their discovery.

Risks identified at discovery level:

| Risk | Owner Ticket | Priority |
|---|---|---|
| WPv2 linked servers dead — jobs failing silently daily | TECH-3478 | Critical |
| Additional stale linked servers beyond WPv2 | TECH-3478 | Critical |
| Client-facing dashboard exposure not confirmed | TECH-3479 / TECH-3480 | Critical |
| VCC framework may be single point of failure — not replicated | All | High |
| Silent ETL failures — errors swallowed, jobs report Succeeded | TECH-3478 | High |
| AWS cost data stale since Sept 2024 — no alert, no one noticed | TECH-3478 / TECH-3480 | High |
| MERGE on large unpartitioned table approaching schedule interval | TECH-3478 | High |
| No runbook or documentation exists for this server | All | Medium |
| Developer Edition not licensed for production use | TECH-3478 | Medium |

→ Full topology and classification in TECH-3481 once upstream themes complete

---

## Critical Findings — Executive Summary

This section documents the most significant findings from the discovery investigation. Each finding is supported by query evidence and has a direct impact on the decommission decision. These findings must be resolved or acknowledged before any decommission work begins.

---

### Finding 1 — 14 Grafana dashboards are actively broken and nobody has noticed

**What was found:**
All SQL Agent jobs feeding the `DBA_VCC_MEMSQL` database were disabled in May 2026. A Grafana dashboard JSON scan (query 12.5, run 2026-07-07) confirmed that 14 dashboards are directly reading from this database. Since the jobs were disabled, every one of these dashboards has been displaying data that is at minimum 2 months out of date. No alert was triggered. No one raised an incident.

**Why this matters for decommission:**
If 14 dashboards are broken and no one has noticed, it raises a serious question about how actively this server is being monitored and relied upon. Before decommissioning, we need to confirm whether these dashboards are still expected to be live, who depends on them, and whether the May 2026 job failure was a deliberate decision or an unresolved incident.

**Affected dashboards — confirmed by query 12.5:**

| Dashboard | Last Updated |
|---|---|
| KAPP Dataset Query and Source Execution | 2024-11-20 |
| KAPP Dataset Query Execution | 2024-11-07 |
| KAPP Client Application Auth Config | 2024-10-29 |
| KAPP Dataset Lambdas Time Outs | 2024-10-23 |
| KAPP Client Config | 2024-09-02 |
| KAPP Workflow Times History | 2024-06-12 |
| KAPP Orphaned and Duplicated Records Report | 2024-03-26 |
| KAPP API Error Reporting | 2024-03-11 |
| Query Performance Dashboard | 2024-03-07 |
| KAPP Workflow History | 2024-03-07 |
| KAPP Client Growth | 2024-02-28 |
| Nifi API Reporting Copy | 2023-09-21 |
| InvestorPress Month End Reporting | 2023-08-10 |
| KAPP Month End Reporting | 2023-08-10 |

**Query proof:**
```sql
-- Run on EW1R-REP-01 via xp_cmdshell + Python (query 12.5)
-- Scans all Grafana dashboard JSON for references to DBA_VCC_MEMSQL
SELECT title, updated FROM dashboard
WHERE is_folder = 0 AND data LIKE '%DBA_VCC_MEMSQL%'
ORDER BY updated DESC;
```

**Action required:** Confirm with yogeshwar.phull and tashvir.babulal — were these jobs intentionally disabled? Are these dashboards still expected to show live data?

---

### Finding 2 — 6 month-end reporting dashboards have no dedicated jobs and depend entirely on the broken MEMSQL feed

**What was found:**
A Grafana dashboard JSON scan (query 12.4, run 2026-07-07) confirmed that 6 dashboards call `REP_MONTHEND_*` stored procedures directly. A SQL Agent job history query (run 2026-07-07) returned only one month-end job: `DBA_VCC_JIRA_MONTHEND_CHECKS`, which ran successfully on 2026-07-01. No dedicated jobs exist for WPv2, Encore, DXM, InvestorPress, or KAPP month-end dashboards.

This means those 5 dashboards have no independent data pipeline. They call stored procedures that read directly from `DBA_VCC_MEMSQL` tables — the same tables that have had no new data since May 2026 (Finding 1). There is no separate job to fix or re-enable. The month-end dashboards are broken as a direct consequence of the MEMSQL feed being disabled.

**Why this matters for decommission:**
Anyone who opened these dashboards for June 2026 month-end reporting received stale or incomplete data with no warning. There is no alert, no error message in Grafana, and no failed job to indicate something is wrong — the dashboards simply show old data silently. This needs to be disclosed to whoever uses these reports.

**Affected dashboards — confirmed by query 12.4:**

| Dashboard | Last Updated | Dedicated job? |
|---|---|---|
| WPv2 Month End Reporting | 2024-06-20 | None — reads DBA_VCC_MEMSQL directly |
| Encore Month End Reporting | 2023-08-10 | None — reads DBA_VCC_MEMSQL directly |
| DXM Month End Reporting | 2023-08-10 | None — reads DBA_VCC_MEMSQL directly |
| InvestorPress Month End Reporting | 2023-08-10 | None — reads DBA_VCC_MEMSQL directly |
| KAPP Month End Reporting | 2023-08-10 | None — reads DBA_VCC_MEMSQL directly |
| Other Services Month End Reporting (Draft) | 2023-07-21 | None — reads DBA_VCC_MEMSQL directly |

**Query proof:**
```sql
-- Grafana dashboard JSON scan (query 12.4) — run 2026-07-07
SELECT title, updated FROM dashboard
WHERE is_folder = 0 AND data LIKE '%REP_MONTHEND%'
ORDER BY updated DESC;

-- SQL Agent job history — run 2026-07-07
SELECT j.name, j.enabled,
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS last_run,
    h.run_status, h.message
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id AND h.step_id = 0
WHERE j.name LIKE '%MONTHEND%' OR j.name LIKE '%month_end%'
ORDER BY h.run_date DESC;
-- Result: only DBA_VCC_JIRA_MONTHEND_CHECKS returned — no jobs for WPv2/Encore/DXM/InvestorPress/KAPP
```

**Action required:** Confirm who uses these dashboards for month-end reporting and disclose that data has been stale since May 2026. Resolving this requires re-enabling the MEMSQL feed jobs (Finding 1) — there is no separate fix for the month-end dashboards alone.

---

### Finding 3 — DBA_VCC_COST is an active Grafana datasource and may be client-facing

**What was found:**
A Grafana dashboard JSON scan (query 12.3, run 2026-07-07) confirmed that 4 dashboards reference `DBA_VCC_COST` directly. This database is on FULL recovery model — the only database on this server deliberately set that way — meaning someone made a conscious decision that this data cannot be lost. The collection job is still running and was last successful on 29 June 2026. One of the confirmed dashboards is named `KAPP Client Utilisation and Growth Report` — a name that strongly suggests client-facing use.

**Why this matters for decommission:**
If any of these dashboards are used for client billing, SLA reporting, or client-facing presentations, decommissioning this server without a confirmed replacement would directly impact clients. This is the single highest-risk finding in this investigation.

**Affected dashboards — confirmed by query 12.3:**

| Dashboard | Last Updated | Risk |
|---|---|---|
| Database Engineering Costs | 2024-10-15 | Internal — DB engineering |
| Database Engineering Sprint Reporting | 2024-03-08 | Internal — engineering management |
| KAPP Client Utilisation and Growth Report | 2024-02-22 | **High — name suggests client-facing** |
| AWS Cost Report Monthly | 2023-10-06 | Internal — note AWS data stale since Sept 2024 |

**Query proof:**
```sql
-- Run on EW1R-REP-01 via xp_cmdshell + Python (query 12.3)
-- Scans all Grafana dashboard JSON for references to DBA_VCC_COST
SELECT title, updated FROM dashboard
WHERE is_folder = 0 AND data LIKE '%DBA_VCC_COST%'
ORDER BY updated DESC;
```

**Action required:** Confirm with tashvir.babulal and rayhaan.suleyman whether `KAPP Client Utilisation and Growth Report` is shared with clients. This must be answered before any decommission date is set.

---

### Finding 4 — Jobs failing silently against decommissioned servers since 25 June 2026

**What was found:**
All 4 WPv2 linked servers (`ew2p-wpv2`, `ew2r-wpv2`, `ue1p-wpv2`, `ue1r-wpv2`) point to RDS instances that no longer exist. DNS does not resolve for any of them. Two SQL Agent jobs — `DBA_VCC_MYSQL_DAILY_CHECKS` and `DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` — have been failing every day since 25 June 2026. No alert was configured. No one was notified.

**Why this matters for decommission:**
This is an existing operational failure that is separate from the decommission work but must be resolved as part of it. The stale linked servers and their referencing jobs need to be cleaned up. Additionally, a full reachability audit across all 109 linked servers is needed — WPv2 is confirmed but further stale targets have also been identified beyond WPv2.

**Evidence — confirmed by SQL Agent job history (run 2026-07-07):**

`DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED` has been failing every day at 01:00 since at least 12 June 2026. The failing step is `SP_AUDIT_WPv2_CLIENTS_DETAILED` — the WPv2 linked server dependency. The job is still enabled and still scheduled. It runs, fails, and reports failure every single day with no owner and no alert.

```
Job: DBA_VCC_MYSQL_AUDIT_DXM_CLIENT_DETAILED
Status: ENABLED
Schedule: Sched1 — daily at 01:00
Failing step: SP_AUDIT_WPv2_CLIENTS_DETAILED
First confirmed failure in history: 2026-06-12
Last confirmed failure: 2026-07-07
Total confirmed consecutive daily failures: 26 days
SP last modified: 2022-11-01 (confirmed via query 13.6 — never updated after WPv2 decommission)
```

For contrast, `DBA - AUDIT - KAPP_Schema_details_Capture` is running and succeeding every day at 11:00 — confirming the SQL Agent service is healthy and the WPv2 failure is isolated to the dead linked servers, not a broader infrastructure issue.

`DBA_VCC_JIRA_MONTHEND_CHECKS` ran successfully on 2026-07-01 at 08:00 — confirming the Jira month-end job completed for June 2026 close.

**Additional stale targets confirmed beyond WPv2:**
- `ew1d-aggr-05`, `ew1d-aggr-15` — Not Online
- `ew1r-aggr-03.gen-rel` — ODBC misconfigured
- `ew1r-aggr-05.gen-rel`, `ew2p-aggr-01.gen-prd`, `ew2p-aggr-02.gen-prd` — Can't connect
- `EW2P-MARKETING-DB` — Not Online, owner unknown

**Action required:** Assign an owner to clean up WPv2 linked servers and referencing job steps. Run a full reachability audit across all 109 linked servers before decommission.

---

### Finding 5 — AWS cost data has been silently wrong for 18 months

**What was found:**
The AWS cost ETL stored procedure `SP_AUDIT_COST_ETL_CLEANUP` has a data type conversion bug — it attempts `CONVERT(decimal(20,10), Cost)` but the `Cost` column is `nvarchar`. This causes the entire MERGE to roll back on every run. The CATCH block swallows the error so the job reports `Succeeded`. The staging table `MON_AWS_Entity_Cost` has 2.4 million rows that have never been processed. The target table `INFO_AWS_Entity_Cost` has been stale since **22 September 2024**. The `INFO_AWS_DE_Entity_Cost` table in `DBA_VCC_COST` has been stale since **5 December 2024**.

**Why this matters for decommission:**
The `AWS Cost Report Monthly` Grafana dashboard reads from `DBA_VCC_COST` which includes this stale AWS cost data. Anyone using that dashboard for cost reporting has been looking at figures that are 18 months out of date without knowing it. This needs to be disclosed before decommission planning proceeds.

**Action required:** Raise as a separate incident ticket. Disclose to whoever uses the AWS Cost Report Monthly dashboard that the data has been stale since September 2024.

---

## Links

| Resource | Location |
|---|---|
| Discovery queries | TECH-3535-planning-and-discovery/discovery-queries.sql |
| Open questions | TECH-3535-planning-and-discovery/open-questions.md |
| Architecture diagram | TECH-3535-planning-and-discovery/ew1r-rep-01-architecture.drawio |
| SQL Server detail | TECH-3478-theme-a-sql-server/investigation-log.md |
| Grafana detail | TECH-3479-theme-b-grafana/investigation-log.md |
| Targets & consumers detail | TECH-3480-theme-c-targets-and-consumers/investigation-log.md |
| Topology & classification | TECH-3481-theme-d-classification-and-topology/investigation-log.md |
| Confluence | TBC — to be published on completion of TECH-3481 |
